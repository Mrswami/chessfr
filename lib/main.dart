import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/game_recorder.dart';
import 'chess_protocol.dart';
import 'game_screen.dart';
import 'game_library_screen.dart';
import 'patterns_library_screen.dart';
import 'services/patterns_provider.dart';
import 'responsive_utils.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    print("✅ Firebase Initialized");
  } catch (e) {
    print("⚠️ Firebase Warning: $e");
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChessUp Pro',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C22F5),
          brightness: Brightness.dark,
          surface: const Color(0xFF121212),
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      ),
      home: const ScanningScreen(),
    );
  }
}

class ScanningScreen extends StatefulWidget {
  const ScanningScreen({super.key});

  @override
  State<ScanningScreen> createState() => _ScanningScreenState();
}

class _ScanningScreenState extends State<ScanningScreen> {
  // Bluetooth State
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeChar;
  String? _autoConnectId;
  bool _isAutoConnecting = false; // Track if we're in auto-connect flow
  bool _hasAttemptedAutoConnect = false; // Prevent multiple auto-connect attempts
  
  // Board State - START WITH KNOWN POSITION
  // Standard starting FEN - we'll track moves from here
  static const String _startingFen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR";
  String _currentFen = _startingFen;
  int? _liftedSquare; // Track which square has a lifted piece
  bool _showProjection = true; // Default to projection mode
  
  final List<LogEntry> _logs = [];
  final TextEditingController _hexController = TextEditingController();
  final ScrollController _logScroll = ScrollController();
  
  // Screen/Mode Tracking
  int _currentScreenId = 0;
  // Known game screens based on observation (add more as discovered)
  // 40 = Menu? 
  // Need to discover valid game screen IDs
  bool get _isGameActive => _currentScreenId != 40 && _currentScreenId != 0;
  
  // Recorder & Patterns
  final GameRecorder _recorder = GameRecorder();
  final PatternsProvider _patternsProvider = PatternsProvider();

  // Auto-sync
  bool _autoSync = false;
  Timer? _autoSyncTimer;
  StreamSubscription<List<int>>? _packetSub;

  // BLE UUIDs (Nordic UART Service)
  final String serviceUuid = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
  final String chWriteUuid = "6e400002-b5a3-f393-e0a9-e50e24dcca9e";
  final String chReadUuid = "6e400003-b5a3-f393-e0a9-e50e24dcca9e";

  @override
  void initState() {
    super.initState();
    _loadSavedDevice();
    _requestPermissions();
    _patternsProvider.loadPatterns();
  }
  
  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    super.dispose();
  }
  
  void _toggleAutoSync() {
    setState(() {
      _autoSync = !_autoSync;
      if (_autoSync) {
        _addLog("🔄 Auto-sync enabled (every 3s)", LogType.system);
        _autoSyncTimer = Timer.periodic(const Duration(seconds: 3), (_) {
          if (_connectedDevice != null) {
            _sendCommand("B0"); // Request board state
          }
        });
      } else {
        _addLog("⏸️ Auto-sync disabled", LogType.system);
        _autoSyncTimer?.cancel();
        _autoSyncTimer = null;
      }
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _loadSavedDevice() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('last_device_id');
    
    if (savedId != null) {
      setState(() {
        _autoConnectId = savedId;
        _isAutoConnecting = true; // Start auto-connect flow
      });
      _addLog("Found saved board: ${savedId.substring(0, 8)}...", LogType.system);
    }
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
    _startScan();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LOGGING
  // ══════════════════════════════════════════════════════════════════════════

  void _addLog(String text, LogType type) {
    if (!mounted) return;
    setState(() {
      _logs.insert(0, LogEntry(timestamp: DateTime.now(), text: text, type: type));
      if (_logs.length > 200) _logs.removeLast();
    });
    print("[${type.name.toUpperCase()}] $text");
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BLUETOOTH SCANNING
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _scanResults = [];
    });
    _addLog("Scanning for ChessUp...", LogType.system);

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    } catch (e) {
      _addLog("Scan Error: $e", LogType.error);
    }

    FlutterBluePlus.scanResults.listen((results) {
      if (!mounted) return;
      
      setState(() {
        _scanResults = results.where((r) {
          return r.device.platformName.toLowerCase().contains("chess");
        }).toList();
      });

      // Auto-connect to previously paired device
      if (_connectedDevice == null && _autoConnectId != null && !_hasAttemptedAutoConnect) {
        try {
          final found = _scanResults.firstWhere(
            (r) => r.device.remoteId.toString() == _autoConnectId
          );
          _hasAttemptedAutoConnect = true;
          _addLog("🔗 Auto-Connecting to saved board...", LogType.system);
          await _connect(found.device, autoConnected: true);
          _autoConnectId = null; // Prevent duplicate connections
        } catch (_) {
          // Device not found yet, keep scanning
        }
      }
      
      // If we have multiple boards and no saved preference, show selection
      if (_scanResults.length > 1 && _autoConnectId == null && _isAutoConnecting) {
        setState(() {
          _isAutoConnecting = false; // Show board selection
        });
        _addLog("Multiple boards found - please select one", LogType.system);
      }
    });

    FlutterBluePlus.isScanning.listen((scanning) {
      if (mounted) setState(() => _isScanning = scanning);
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BLUETOOTH CONNECTION
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _connect(BluetoothDevice device, {bool autoConnected = false}) async {
    if (_isScanning) await FlutterBluePlus.stopScan();

    _addLog("Connecting to ${device.platformName}...", LogType.system);
    
    try {
      // Monitor connection state for unexpected disconnects
      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected && _connectedDevice != null) {
          _handleDisconnect();
        }
      });

      await device.connect(autoConnect: false);
      
      // Save for auto-connect next time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_device_id', device.remoteId.toString());

      _addLog("Connected! Discovering services...", LogType.system);
      
      List<BluetoothService> services = await device.discoverServices();
      bool foundService = false;

      for (var service in services) {
        if (service.uuid.toString() == serviceUuid) {
          foundService = true;
          for (var c in service.characteristics) {
            if (c.uuid.toString() == chWriteUuid) {
              _writeChar = c;
              _addLog("Write Channel Ready 🟢", LogType.success);
            }
            if (c.uuid.toString() == chReadUuid) {
              _addLog("Notifications Enabled 🔵", LogType.success);
              await c.setNotifyValue(true);
              
              // FIX: Cancel existing listener to avoid duplicates
              await _packetSub?.cancel();
              _packetSub = c.lastValueStream.listen(_handlePacket);
            }
          }
        }
      }

      if (foundService) {
        setState(() {
          _connectedDevice = device;
          // Auto-enable projection mode if this was an auto-connect
          if (autoConnected) {
            _showProjection = true;
            _isAutoConnecting = false;
          }
        });
        _addLog("✅ Connected! ${autoConnected ? 'Opening projection...' : 'Board ready.'}", LogType.success);
      } else {
        _addLog("ChessUp service not found!", LogType.error);
        device.disconnect();
      }
    } catch (e) {
      _addLog("Connection failed: $e", LogType.error);
      setState(() {
        _isAutoConnecting = false; // Show scanner on failure
      });
    }
  }

  void _handleDisconnect() {
    if (!mounted) return;
    
    setState(() {
      _connectedDevice = null;
      _currentFen = "No Board Data";
    });
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("⚠️ Connection Lost"),
        content: const Text("The ChessUp board has disconnected."),
        actions: [
          TextButton(
            child: const Text("Reconnect"),
            onPressed: () {
              Navigator.pop(ctx);
              _startScan();
            },
          )
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PACKET HANDLING (THE BRAIN)
  // ══════════════════════════════════════════════════════════════════════════

  final List<int> _packetBuffer = [];
  bool _isAccumulating = false;

  /// Decode piece type index from BLE packet (discovered from APK decompilation)
  /// Maps: 0=Pawn, 1=Rook, 2=Knight, 3=Bishop, 4=Queen, 5=King
  String _decodePieceType(int index) {
    switch (index) {
      case 0: return 'Pawn';
      case 1: return 'Rook';
      case 2: return 'Knight';
      case 3: return 'Bishop';
      case 4: return 'Queen';
      case 5: return 'King';
      default: return 'Unknown($index)';
    }
  }

  void _handlePacket(List<int> value) {
    if (value.isEmpty) return;
    
    String hex = value.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    LogType type = LogType.rx;
    String meaning = "";

    // Header logic
    int header = value[0];

    // CASE 1: Start of a new Board State (0x67)
    if (header == 0x67) {
      _packetBuffer.clear();
      _packetBuffer.addAll(value);
      _isAccumulating = true;
      
      if (_packetBuffer.length >= 73) {
        _processFullState(_packetBuffer);
        _isAccumulating = false;
        meaning = "[FULL STATE RECEIVED]";
      } else {
        meaning = "[STATE START: ${value.length}/73 bytes]";
        _addLog("📍 State chunk: ${value.length} bytes", LogType.system);
        return; // Wait for more
      }
    } 
    // CASE 2: Continuation of a packet
    else if (_isAccumulating) {
      _packetBuffer.addAll(value);
      if (_packetBuffer.length >= 73) {
        _processFullState(_packetBuffer);
        _isAccumulating = false;
        meaning = "[FULL STATE COMPLETED]";
      } else {
        meaning = "[STATE CHUNK: ${_packetBuffer.length}/73 bytes]";
        return; // Still accumulating
      }
    }
    // CASE 3: Other headers
    else {
      switch (header) {
        case 0xB2: 
          meaning = "[Status Report]"; 
          break;
        case 0xB0:
          meaning = "[Request ACK]";
          if (value.length > 1 && value[1] == 1) meaning += " (OK)";
          break;
        case 0x26: 
          meaning = "[Error/NACK]"; 
          type = LogType.error; 
          break;
        case 0xE9:
          final screenId = (value.length >= 2) ? value[1] : 0;
          setState(() => _currentScreenId = screenId);
          meaning = "[Screen ID: $screenId]";
          break;
        case 0xB8: // PIECE_TOUCH - Lift/Touch event with coordinate AND piece type
          if (value.length >= 3) {
            final sq = value[1];           // Square index (0-63)
            final pieceTypeIdx = value[2]; // Piece type (0-5)
            final piece = _decodePieceType(pieceTypeIdx);
            final square = _chessUpToAlgebraic(sq);
            setState(() => _liftedSquare = sq);
            _addLog("💡 Touch: $square [$piece]", LogType.system);
            meaning = "[PIECE_TOUCH: $square, $piece]";
            
            // Backup Strategy: The board sometimes swallows Release/Placement events in game mode.
            // We start a "Sync Watchdog" to poll board state for the next 2 seconds.
            _startAggressiveSync();
          }
          break;
        case 0xBB: // Release Touch
          _addLog("💡 Release detected", LogType.system);
          setState(() => _liftedSquare = null);
          // Aggressive sync: request state immediately and again in 500ms
          _sendCommand("B0");
          Future.delayed(const Duration(milliseconds: 600), () => _sendCommand("B0"));
          break;
        case 0xA4: // ON_PLACEMENT - Piece placed at specific col/row
          if (value.length >= 3) {
            final col = value[1]; // Column (0-7)
            final row = value[2]; // Row (0-7)
            // Convert col,row to square index (0-63)
            final sq = row * 8 + col;
            final square = _chessUpToAlgebraic(sq);
            setState(() => _liftedSquare = null);
            _addLog("📍 Placement: $square", LogType.success);
            meaning = "[ON_PLACEMENT: $square]";
          } else {
            _addLog("📍 Piece Set Down (no coords)", LogType.success);
            setState(() => _liftedSquare = null);
          }
          _sendCommand("B0"); // Sync board state after placement
          break;
        case 0x42: // Navigation/Button Event (Back/Menu)
          if (_recorder.isRecording) {
             _recorder.stopRecording();
             _recorder.saveGameToFirebase("Aborted (Menu)");
             
             // Reset App UI to ready state
             setState(() {
               _currentFen = _startingFen;
               _liftedSquare = null;
             });
             _addLog("💾 Auto-Saved & Reset", LogType.success);
          }
          meaning = "[Nav/Menu: ${value.map((e)=>e.toRadixString(16)).join(',')}]";
          break;
        case 0xA3: // MOVE - The board confirms a move!
          if (value.length >= 3) {
            final fromSq = value[1];
            final toSq = value[2];
            final from = _chessUpToAlgebraic(fromSq);
            final to = _chessUpToAlgebraic(toSq);
            
            _addLog("🚀 MOVE DETECTED: $from -> $to", LogType.success);
            meaning = "[MOVE: $from -> $to]";
            
            // Immediate sync to get full FEN
             _sendCommand("B0"); 
          }
          break;
          
        case 0x19: // BOARD INFO RESPONSE (from C9)
          meaning = "[BOARD INFO]";
          _addLog("ℹ️ Info: $hex", LogType.system);
          break;
        case 0x6B: // History/Reconcile
          meaning = "[History Update]";
          if (value.length >= 3) {
            final moveCount = value[1] << 8 | value[2];
            meaning += " ($moveCount moves total)";
          }
          _sendCommand("B0"); // Sync board after history update
          break;
        default:
          // Enhanced logging for unknown headers - helps discover new packet types
          meaning = "UNKNOWN (0x${header.toRadixString(16).padLeft(2, '0').toUpperCase()})";
          String details = "Header=0x${header.toRadixString(16).padLeft(2, '0')}";
          if (value.length >= 2) {
            details += " B1=${value[1]}";
            // Try to interpret as square
            if (value[1] < 64) {
              details += " (sq=${_chessUpToAlgebraic(value[1])})";
            }
          }
          if (value.length >= 3) {
            details += " B2=${value[2]}";
          }
          _addLog("❓ UNKNOWN: $details | Raw: $hex", LogType.error);
      }
    }

    _addLog("RX: $hex $meaning", type);
  }

  String _lastSyncedFen = "";

  void _processFullState(List<int> fullPacket) {
    try {
      String fen = ChessProtocol.parseBoardState(fullPacket);
      
      // Only process if it's a valid FEN and changed
      if (fen.contains("/") && fen != _lastSyncedFen) {
        
        // Simple diff: detecting moves
        if (_lastSyncedFen.isNotEmpty) {
           _detectAndLogMove(_lastSyncedFen, fen);
        }
        
        _lastSyncedFen = fen;
        // RECORDER HOOK
        _recorder.handleNewFen(fen);

        // PATTERN ORACLE HOOK
        final pattern = _patternsProvider.findByFen(fen);
        if (pattern != null) {
          _addLog("🔮 ORACLE: Pattern Detected! [${pattern.name}]", LogType.success);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("🔮 Pattern Detected: ${pattern.name}"),
                backgroundColor: const Color(0xFF6C22F5),
                action: SnackBarAction(
                  label: "VIEW", 
                  textColor: Colors.white,
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatternsLibraryScreen()))
                ),
              )
            );
          }
        }

        setState(() {
            _currentFen = fen;
            // _liftedSquare = null; // Keep the highlight so we see what we moved
        });
        _addLog("🏁 SYNCED: $fen", LogType.success);
      }
    } catch (e) {
      _addLog("Sync Error: $e", LogType.error);
    }
  }

  // Basic diff to see what changed (State Diffing strategy)
  void _detectAndLogMove(String oldFen, String newFen) {
    // This is a naive diff just for logging, the UI updates from FEN directly
    // Ideally we would use a chess library to validate the move
    _addLog("🔄 Board State Changed!", LogType.success);
  }
  
  // Aggressive Sync Watchdog
  // Polls board state 4 times over 2 seconds to catch moves if event packets are missing
  void _startAggressiveSync() {
    int checks = 0;
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      checks++;
      if (checks > 8 || _connectedDevice == null) { 
        timer.cancel();
      } else {
        // Identified Solution: Sending 0x67 (Response Header) as a command triggers the board to dump its state!
        _sendCommand("67");
      }
    });
  }

  // Translates ChessUp hardware IDs to Algebraic (a1-h8)
  String _chessUpToAlgebraic(int sq) {
    int internalIdx = _chessUpToIndex(sq);
    if (internalIdx == -1) return "??";
    int rank = internalIdx ~/ 8;
    int file = internalIdx % 8;
    return "${String.fromCharCode('a'.codeUnitAt(0) + file)}${rank + 1}";
  }

  // FIXED: OFFICIAL STRIDE IS 8
  int _chessUpToIndex(int hardwareSq) {
    int rank = hardwareSq ~/ 8;
    int file = hardwareSq % 8;
    
    if (rank >= 0 && rank < 8 && file >= 0 && file < 8) {
      return rank * 8 + file;
    }
    return -1;
  }
  
  // Parse 0x67 board state packet
  // This packet maps piece IDs to square positions
  // For simplicity, we'll just request a 71 packet instead
  String _parse67Packet(List<int> packet) {
    // Request the 71 packet which uses the ChessProtocol parser
    _sendCommand("7101");
    return _currentFen; // Keep current until 71 arrives
  }
  
  void _applyMove(int from, int to) {
    if (from < 0 || from > 63 || to < 0 || to > 63) {
        _addLog("Move Error: Out of bounds ($from → $to)", LogType.error);
        return;
    }
    
    // Debug: Log the move indices
    _addLog("APPLY: index $from → $to", LogType.system);
    
    // Convert FEN to a mutable board array, apply move, convert back
    List<String?> board = _fenToBoard(_currentFen);
    
    // Debug: Show what piece is being moved
    String? piece = board[from];
    _addLog("Moving piece: ${piece ?? 'EMPTY'}", LogType.system);
    
    if (piece == null) {
      _addLog("Warning: No piece at source square!", LogType.error);
    }
    
    board[from] = null;
    board[to] = piece;
    
    // Convert back to FEN and update state
    String newFen = _boardToFen(board);
    _addLog("New FEN: $newFen", LogType.system);
    
    setState(() {
      _currentFen = newFen;
    });
  }
  
  List<String?> _fenToBoard(String fen) {
    List<String?> board = List.filled(64, null);
    try {
      String placement = fen.split(' ')[0];
      int rank = 7;
      int file = 0;
      
      for (int i = 0; i < placement.length; i++) {
        String c = placement[i];
        if (c == '/') {
          rank--;
          file = 0;
        } else {
          int? skip = int.tryParse(c);
          if (skip != null) {
            file += skip;
          } else {
            if (rank >= 0 && rank < 8 && file >= 0 && file < 8) {
              board[rank * 8 + file] = c;
            }
            file++;
          }
        }
      }
    } catch (e) {
      _addLog("FEN Parse Error: $e", LogType.error);
    }
    return board;
  }
  
  String _boardToFen(List<String?> board) {
    StringBuffer fen = StringBuffer();
    for (int rank = 7; rank >= 0; rank--) {
      int empty = 0;
      for (int file = 0; file < 8; file++) {
        int sq = rank * 8 + file;
        String? piece = board[sq];
        if (piece == null) {
          empty++;
        } else {
          if (empty > 0) {
            fen.write(empty);
            empty = 0;
          }
          fen.write(piece);
        }
      }
      if (empty > 0) fen.write(empty);
      if (rank > 0) fen.write('/');
    }
    return fen.toString();
  }

  Future<void> _sendCommand(String hex) async {
    if (hex == "DUMP_ALL") {
      _addLog("Requesting Full State Dump...", LogType.system);
      await _sendCommand("3C"); // Identify
      await Future.delayed(const Duration(milliseconds: 200));
      await _sendCommand("2100"); // Settings
      await Future.delayed(const Duration(milliseconds: 200));
      await _sendCommand("B0");   // FEN
      await Future.delayed(const Duration(milliseconds: 200));
      await _sendCommand("7101"); // Full Board State
      return;
    }
    
    if (hex == "PLAY_SEQ") {
      _addLog("Forcing Game Mode...", LogType.system);
      await _sendCommand("2401"); // Start Game
      await Future.delayed(const Duration(milliseconds: 300));
      await _sendCommand("4001"); // Mode Change (often board logic switch)
      await Future.delayed(const Duration(milliseconds: 300));
      await _sendCommand("B0");   // FEN Sync
      return;
    }

    if (hex == "INIT_SEQ") {
      _addLog("Running Handshake Sequence...", LogType.system);
      await _sendCommand("3C");
      await Future.delayed(const Duration(milliseconds: 300));
      await _sendCommand("2401");
      await Future.delayed(const Duration(milliseconds: 300));
      await _sendCommand("2100");
      return;
    }

    if (hex == "RESET") {
      setState(() {
        _currentFen = _startingFen;
        _liftedSquare = null;
      });
      _addLog("Position Reset to Starting", LogType.system);
      return;
    }
    
    if (_connectedDevice == null || _writeChar == null) {
      _addLog("Not connected", LogType.error);
      return;
    }
    
    hex = hex.replaceAll(" ", "").toLowerCase();
    
    try {
      List<int> bytes = [];
      for (int i = 0; i < hex.length; i += 2) {
        bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
      }
      await _writeChar!.write(bytes);
      _addLog("TX: $hex", LogType.tx);
    } catch (e) {
      _addLog("TX Error: $e", LogType.error);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // UI BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    // Show Projection Screen if toggled ON
    if (_connectedDevice != null && _showProjection) {
      return GameProjectionScreen(
        fen: _currentFen,
        lastLogs: _logs.take(10).map((l) => l.text).toList(),
        liftedSquare: _liftedSquare != null ? _chessUpToAlgebraic(_liftedSquare!) : null,
        onBack: () => setState(() => _showProjection = false),
        onDisconnect: () async {
          // Auto-save on disconnect
          if (_recorder.isRecording) {
             print("🔌 Disconnected - Saving Game...");
             _recorder.stopRecording();
             await _recorder.saveGameToFirebase("Disconnect");
          }
          
          _connectedDevice?.disconnect();
          setState(() {
            _connectedDevice = null;
            _currentFen = _startingFen;
            _showProjection = false;
          });
        },
      );
    }
    
    // Show Control Panel if connected (but not in projection mode)
    if (_connectedDevice != null) {
      return _buildControlPanel();
    }
    
    // Show loading screen during auto-connect
    if (_isAutoConnecting) {
      return _buildAutoConnectLoading();
    }
    
    // Show Scanner (only if not auto-connecting)
    return _buildScanner();
  }

  Widget _buildAutoConnectLoading() {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF6C22F5),
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),
            ResponsiveText(
              "Connecting to ChessUp...",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 12),
            ResponsiveText(
              "Please wait",
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanner() {
    return Scaffold(
      appBar: AppBar(title: const Text("ChessUp Pro")),
      floatingActionButton: FloatingActionButton(
        onPressed: _isScanning ? null : _startScan,
        backgroundColor: _isScanning ? Colors.grey : const Color(0xFF6C22F5),
        child: Icon(_isScanning ? Icons.hourglass_top : Icons.search),
      ),
      body: ResponsiveLayout(
        mobile: (context) => _buildScannerContent(context),
        tablet: (context) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: ResponsiveUtils.getMaxContentWidth(context),
            ),
            child: _buildScannerContent(context),
          ),
        ),
      ),
    );
  }

  Widget _buildScannerContent(BuildContext context) {
    final padding = ResponsiveUtils.getResponsivePadding(context);
    
    if (_scanResults.isEmpty) {
      return Center(
        child: ResponsiveText(
          _isScanning ? "Scanning..." : "No ChessUp boards found.",
          style: const TextStyle(fontSize: 16),
        ),
      );
    }
    
    return ListView.builder(
      padding: padding,
      itemCount: _scanResults.length,
      itemBuilder: (c, i) {
        final d = _scanResults[i].device;
        return Card(
          margin: EdgeInsets.only(bottom: ResponsiveUtils.getResponsiveSpacing(context)),
          child: ListTile(
            leading: const Icon(Icons.bluetooth, color: Colors.blue, size: 32),
            title: ResponsiveText(
              d.platformName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(d.remoteId.toString()),
            trailing: ElevatedButton(
              onPressed: () => _connect(d),
              child: const Text("CONNECT"),
            ),
          ),
        );
      },
    );
  }

  Widget _buildControlPanel() {
    return Scaffold(
      appBar: AppBar(
        title: Text(_connectedDevice!.platformName),
        actions: [
          IconButton(
            icon: const Icon(Icons.power_settings_new),
            onPressed: () {
              _connectedDevice!.disconnect();
              setState(() => _connectedDevice = null);
            },
          )
        ],
      ),
      body: ResponsiveLayout(
        mobile: (context) => _buildControlPanelContent(context, isMobile: true),
        tablet: (context) => _buildControlPanelContent(context, isMobile: false),
      ),
    );
  }

  Widget _buildControlPanelContent(BuildContext context, {required bool isMobile}) {
    final padding = ResponsiveUtils.getResponsivePadding(context);
    final spacing = ResponsiveUtils.getResponsiveSpacing(context);
    
    return SingleChildScrollView(
      child: Padding(
        padding: padding,
        child: isMobile ? _buildMobileLayout(spacing) : _buildTabletLayout(context, spacing),
      ),
    );
  }

  Widget _buildMobileLayout(double spacing) {
    return Column(
      children: [
        _buildStatusIndicator(spacing),
        SizedBox(height: spacing),
        _buildFenArea(spacing),
        SizedBox(height: spacing),
        _buildCommandControls(spacing),
        SizedBox(height: spacing),
        _buildRecordingControls(spacing),
        SizedBox(height: spacing),
        _buildLogsArea(),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context, double spacing) {
    return Column(
      children: [
        _buildStatusIndicator(spacing),
        SizedBox(height: spacing),
        _buildFenArea(spacing),
        SizedBox(height: spacing),
        // Two-column layout for controls on tablets
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  _buildCommandControls(spacing),
                  SizedBox(height: spacing),
                  _buildRecordingControls(spacing),
                ],
              ),
            ),
            SizedBox(width: spacing),
            Expanded(
              child: _buildLogsArea(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(double spacing) {
    return Container(
      padding: EdgeInsets.all(spacing),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: _liftedSquare != null ? Colors.greenAccent : Colors.grey,
            radius: 8,
          ),
          SizedBox(width: spacing),
          Expanded(
            child: Text(
              _liftedSquare != null ? "LIFTED: ${_chessUpToAlgebraic(_liftedSquare!)}" : "SENSORS ACTIVE",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _isGameActive ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: _isGameActive ? Colors.green : Colors.orange),
            ),
            child: Text(
              "MODE: $_currentScreenId",
              style: TextStyle(
                fontSize: 12,
                color: _isGameActive ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFenArea(double spacing) {
    return Container(
      padding: EdgeInsets.all(spacing),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: SelectableText(
              _currentFen,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Colors.greenAccent),
            ),
          ),
          SizedBox(height: spacing),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _QuickBtn("Reset", "RESET"),
              _QuickBtn("FORCE PLAY", "PLAY_SEQ"),
              _QuickBtn("DUMP ALL", "DUMP_ALL"),
              _QuickBtn("LED TEST", "3E010C01"),
              _QuickBtn("FEN (B0)", "B0"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommandControls(double spacing) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _hexController,
                decoration: const InputDecoration(
                  labelText: "Send Hex",
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            SizedBox(width: spacing),
            IconButton.filled(
              onPressed: () => _sendCommand(_hexController.text),
              icon: const Icon(Icons.send),
            ),
          ],
        ),
        SizedBox(height: spacing),
        SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C22F5),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.auto_awesome),
                label: const Text("PATTERN ORACLE"),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatternsLibraryScreen())),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.tv),
                label: const Text("OPEN PROJECTION (Force)"),
                onPressed: () => setState(() => _showProjection = true),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingControls(double spacing) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _recorder.isRecording ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                ),
                icon: Icon(_recorder.isRecording ? Icons.stop : Icons.fiber_manual_record),
                label: Text(_recorder.isRecording ? "STOP REC" : "REC GAME"),
                onPressed: () {
                  setState(() {
                    if (_recorder.isRecording) {
                      _recorder.stopRecording();
                    } else {
                      _recorder.startNewGame();
                      _recorder.handleNewFen(_currentFen);
                    }
                  });
                },
              ),
            ),
            SizedBox(width: spacing),
            IconButton.filledTonal(
              icon: const Icon(Icons.cloud_upload),
              tooltip: "Save to Firebase",
              onPressed: () async {
                _recorder.stopRecording();
                setState(() {});
                await _recorder.saveGameToFirebase("1-0");
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Game Saved to Cloud! ☁️")));
                }
              },
            ),
          ],
        ),
        SizedBox(height: spacing),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.history),
            label: const Text("OPEN CLOUD LIBRARY"),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const GameLibraryScreen()));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLogsArea() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _logs.length,
        itemBuilder: (c, i) {
          final log = _logs[i];
          Color color = Colors.white70;
          if (log.type == LogType.tx) color = Colors.greenAccent;
          if (log.type == LogType.rx) color = Colors.cyan;
          if (log.type == LogType.error) color = Colors.redAccent;
          if (log.type == LogType.success) color = Colors.amber;

          return Text(
            "${log.timestamp.second}:${log.timestamp.millisecond} ${log.text}",
            style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 11),
          );
        },
      ),
    );
  }

  Widget _QuickBtn(String label, String cmd) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      onPressed: () => _sendCommand(cmd),
      child: Text(label),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  const _ControlButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ══════════════════════════════════════════════════════════════════════════════

enum LogType { system, rx, tx, error, success }

class LogEntry {
  final DateTime timestamp;
  final String text;
  final LogType type;
  LogEntry({required this.timestamp, required this.text, required this.type});
}
