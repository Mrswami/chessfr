import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'chess_protocol.dart';
import 'game_screen.dart';
import 'dart:async';

void main() {
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
  
  // Board State - START WITH KNOWN POSITION
  // Standard starting FEN - we'll track moves from here
  static const String _startingFen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR";
  String _currentFen = _startingFen;
  int? _liftedSquare; // Track which square has a lifted piece
  bool _showProjection = false; // Toggle between debug and projection view
  
  final List<LogEntry> _logs = [];
  final TextEditingController _hexController = TextEditingController();
  final ScrollController _logScroll = ScrollController();

  // BLE UUIDs (Nordic UART Service)
  final String serviceUuid = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
  final String chWriteUuid = "6e400002-b5a3-f393-e0a9-e50e24dcca9e";
  final String chReadUuid = "6e400003-b5a3-f393-e0a9-e50e24dcca9e";

  @override
  void initState() {
    super.initState();
    _loadSavedDevice();
    _requestPermissions();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _loadSavedDevice() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoConnectId = prefs.getString('last_device_id');
    });
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
      if (_connectedDevice == null && _autoConnectId != null) {
        try {
          final found = _scanResults.firstWhere(
            (r) => r.device.remoteId.toString() == _autoConnectId
          );
          _addLog("Auto-Connecting to known board...", LogType.system);
          _connect(found.device);
          _autoConnectId = null; // Prevent duplicate connections
        } catch (_) {
          // Device not found yet, keep scanning
        }
      }
    });

    FlutterBluePlus.isScanning.listen((scanning) {
      if (mounted) setState(() => _isScanning = scanning);
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BLUETOOTH CONNECTION
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _connect(BluetoothDevice device) async {
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
              c.lastValueStream.listen(_handlePacket);
            }
          }
        }
      }

      if (foundService) {
        setState(() => _connectedDevice = device);
        _addLog("✅ Connected! Board is in free play mode.", LogType.success);
      } else {
        _addLog("ChessUp service not found!", LogType.error);
        device.disconnect();
      }
    } catch (e) {
      _addLog("Connection failed: $e", LogType.error);
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

  void _handlePacket(List<int> value) {
    String hex = value.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    
    // DEBUG: Log EVERY packet immediately
    print("📦 RAW PACKET: $hex (${value.length} bytes)");
    
    String meaning = "";
    LogType type = LogType.rx;

    if (hex.startsWith("b2")) {
      meaning = "[Status Report]";
    } else if (hex.startsWith("26")) {
      meaning = "[Error/NACK]";
      type = LogType.error;
    } else if (hex.startsWith("e9")) {
      // E9 packets send PIECE IDs, not square coordinates!
      // We can't reliably track moves with these - we need the full board state instead.
      int rawByte = value.length > 1 ? value[1] : 0;
      bool isLifted = (rawByte & 0x40) != 0;
      int pieceId = rawByte & 0x3F;
      
      if (isLifted) {
        meaning = "⬆️ Piece $pieceId lifted";
        _addLog("⬆️ Piece ID $pieceId lifted", LogType.success);
      } else {
        meaning = "⬇️ Piece $pieceId placed";
        _addLog("⬇️ Piece ID $pieceId placed", LogType.success);
        
        // DISABLED: This command might lock the board
        // _sendCommand("6401"); // Request board state
      }
    } else if (hex.startsWith("67")) {
      // 0x67 = Board state packet with piece positions
      meaning = "[Board State Response]";
      _addLog("📍 Received board state (${value.length} bytes)", LogType.system);
      
      // Parse the 67 packet to build FEN
      // Format: 67 [piece positions...]
      if (value.length >= 66) {
        try {
          String newFen = _parse67Packet(value);
          if (newFen.isNotEmpty && newFen != _currentFen) {
            print("📌 Board state changed!");
            print("📌 OLD: $_currentFen");
            print("📌 NEW: $newFen");
            setState(() {
              _currentFen = newFen;
            });
          }
        } catch (e) {
          _addLog("Error parsing 67 packet: $e", LogType.error);
        }
      }
    } else if (hex.startsWith("71")) {
      meaning = "[Board State Dump]";
      // Print the raw bytes to help the AI map the pieces
      _addLog("RAW PIECES: ${value.skip(2).take(64).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}", LogType.system);
      try {
        String fen = ChessProtocol.parseBoardState(value);
        if (fen.contains("/") && !fen.contains("?")) {
          setState(() => _currentFen = fen);
          _addLog("SYNC: $fen", LogType.success);
        }
      } catch (_) {}
    } else {
      meaning = "🔥 UNKNOWN";
      type = LogType.success;
    }

    _addLog("RX: $hex $meaning", type);
  }
  
  // Translates ChessUp hardware IDs to Algebraic (a1-h8)
  String _chessUpToAlgebraic(int sq) {
    int internalIdx = _chessUpToIndex(sq);
    if (internalIdx == -1) return "??";
    int rank = internalIdx ~/ 8;
    int file = internalIdx % 8;
    return "${String.fromCharCode('a'.codeUnitAt(0) + file)}${rank + 1}";
  }

  // THE TRANSLATION LAYER (Corrected for 12-wide stride)
  int _chessUpToIndex(int hardwareSq) {
    // ChessUp Pro hardware uses a 12-column grid.
    // Index 40: (40 ~/ 12) = Rank 3, (40 % 12) = File 4 => e4. Correct!
    int rank = hardwareSq ~/ 12;
    int file = hardwareSq % 12;
    
    // Map to our internal 0-63 (rank*8 + file)
    if (rank >= 0 && rank < 8 && file >= 0 && file < 8) {
      return rank * 8 + file;
    }
    return -1; // Out of chess bounds
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
    // Handle special commands
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
        onDisconnect: () {
          _connectedDevice?.disconnect();
          setState(() {
            _connectedDevice = null;
            _currentFen = _startingFen;
            _showProjection = false;
          });
        },
      );
    }
    
    // Show Control Panel if connected
    if (_connectedDevice != null) {
      return _buildControlPanel();
    }
    
    // Show Scanner
    return _buildScanner();
  }

  Widget _buildScanner() {
    return Scaffold(
      appBar: AppBar(title: const Text("ChessUp Pro")),
      floatingActionButton: FloatingActionButton(
        onPressed: _isScanning ? null : _startScan,
        backgroundColor: _isScanning ? Colors.grey : const Color(0xFF6C22F5),
        child: Icon(_isScanning ? Icons.hourglass_top : Icons.search),
      ),
      body: _scanResults.isEmpty
          ? Center(child: Text(_isScanning ? "Scanning..." : "No ChessUp boards found."))
          : ListView.builder(
              itemCount: _scanResults.length,
              itemBuilder: (c, i) {
                final d = _scanResults[i].device;
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.bluetooth, color: Colors.blue),
                    title: Text(d.platformName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(d.remoteId.toString()),
                    trailing: ElevatedButton(
                      onPressed: () => _connect(d),
                      child: const Text("CONNECT"),
                    ),
                  ),
                );
              },
            ),
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
      body: Column(
        children: [
          // FEN Display
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.black26,
            child: Column(
              children: [
                Text(_currentFen, style: const TextStyle(fontSize: 14, fontFamily: 'monospace', color: Colors.greenAccent)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _QuickBtn("Reset Pos", "RESET"),
                    _QuickBtn("Force Start", "4000"),
                    _QuickBtn("Sync (71)", "7101"),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: const Icon(Icons.tv),
                    label: const Text("SHOW BOARD (Projection)", style: TextStyle(fontSize: 18)),
                    onPressed: () => setState(() => _showProjection = true),
                  ),
                ),
              ],
            ),
          ),
          
          // Manual Input
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _hexController,
                    decoration: const InputDecoration(
                      labelText: "Raw Hex Command",
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (val) => _sendCommand(val),
                  ),
                ),
                const SizedBox(width: 10),
                // Added Sync button next to hex input
                _ControlButton(
                  label: "Sync (71)",
                  icon: Icons.sync,
                  onPressed: () => _sendCommand("7101"),
                  color: Colors.blue,
                ),
                const SizedBox(width: 10),
                FloatingActionButton.small(
                  onPressed: () => _sendCommand(_hexController.text),
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),

          const Divider(),

          // Log View
          Expanded(
            child: ListView.builder(
              controller: _logScroll,
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                Color color = Colors.white;
                switch (log.type) {
                  case LogType.rx: color = Colors.cyanAccent; break;
                  case LogType.tx: color = Colors.greenAccent; break;
                  case LogType.error: color = Colors.redAccent; break;
                  case LogType.system: color = Colors.grey; break;
                  case LogType.success: color = Colors.green; break;
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Text(
                    "${log.timestamp.second}:${log.timestamp.millisecond.toString().padLeft(3, '0')} ${log.text}",
                    style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 12),
                  ),
                );
              },
            ),
          ),
        ],
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
