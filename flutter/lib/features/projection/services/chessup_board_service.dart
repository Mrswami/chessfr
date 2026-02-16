import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences/shared_preferences.dart';
import 'chess_protocol.dart';
import 'game_recorder.dart';

enum LogType { system, tx, rx, success, error }

class LogEntry {
  final DateTime timestamp;
  final String text;
  final LogType type;
  LogEntry({required this.timestamp, required this.text, required this.type});
}

class ChessUpBoardService extends ChangeNotifier {
  // Singleton
  static final ChessUpBoardService _instance = ChessUpBoardService._internal();
  factory ChessUpBoardService() => _instance;
  ChessUpBoardService._internal();

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeChar;
  StreamSubscription<List<int>>? _packetSub;
  
  String _currentFen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";
  int? _liftedSquare;
  bool _isScanning = false;
  List<ScanResult> _scanResults = [];
  final List<LogEntry> _logs = [];
  
  // Service UUIDs
  final String serviceUuid = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
  final String chWriteUuid = "6e400002-b5a3-f393-e0a9-e50e24dcca9e";
  final String chReadUuid = "6e400003-b5a3-f393-e0a9-e50e24dcca9e";

  // Getters
  BluetoothDevice? get connectedDevice => _connectedDevice;
  String get currentFen => _currentFen;
  int? get liftedSquare => _liftedSquare;
  bool get isScanning => _isScanning;
  List<ScanResult> get scanResults => _scanResults;
  List<LogEntry> get logs => _logs;
  bool get isConnected => _connectedDevice != null;

  final GameRecorder _recorder = GameRecorder();

  Future<void> startScan() async {
    if (_isScanning) return;
    _isScanning = true;
    _scanResults = [];
    notifyListeners();
    _addLog("Scanning for ChessUp...", LogType.system);

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    } catch (e) {
      _addLog("Scan Error: $e", LogType.error);
    }

    FlutterBluePlus.scanResults.listen((results) {
      _scanResults = results.where((r) {
        return r.device.platformName.toLowerCase().contains("chess");
      }).toList();
      notifyListeners();
    });

    FlutterBluePlus.isScanning.listen((scanning) {
      _isScanning = scanning;
      notifyListeners();
    });
  }

  Future<void> connect(BluetoothDevice device) async {
    await FlutterBluePlus.stopScan();
    _addLog("Connecting to ${device.platformName}...", LogType.system);
    
    try {
      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected && _connectedDevice != null) {
          _handleDisconnect();
        }
      });


      await device.connect(autoConnect: false, license: License.free);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_device_id', device.remoteId.toString());

      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        if (service.uuid.toString() == serviceUuid) {
          for (var c in service.characteristics) {
            if (c.uuid.toString() == chWriteUuid) _writeChar = c;
            if (c.uuid.toString() == chReadUuid) {
              await c.setNotifyValue(true);
              await _packetSub?.cancel();
              _packetSub = c.lastValueStream.listen(_handlePacket);
            }
          }
        }
      }

      _connectedDevice = device;
      _addLog("✅ Connected!", LogType.success);
      notifyListeners();
      
      // Initial Sync
      await sendCommand("B0"); // Request FEN
    } catch (e) {
      _addLog("Connection failed: $e", LogType.error);
    }
  }

  void _handleDisconnect() {
    _connectedDevice = null;
    _writeChar = null;
    _packetSub?.cancel();
    _addLog("⚠️ Disconnected", LogType.error);
    if (_recorder.isRecording) {
      _recorder.stopRecording();
    }
    notifyListeners();
  }

  void _addLog(String text, LogType type) {
    _logs.insert(0, LogEntry(timestamp: DateTime.now(), text: text, type: type));
    if (_logs.length > 100) _logs.removeLast();
    notifyListeners();
    debugPrint("[BOARD] $text");
  }

  final List<int> _packetBuffer = [];
  bool _isAccumulating = false;

  void _handlePacket(List<int> value) {
    if (value.isEmpty) return;
    String hex = value.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    
    int header = value[0];
    if (header == 0x67) {
      _packetBuffer.clear();
      _packetBuffer.addAll(value);
      _isAccumulating = true;
      if (_packetBuffer.length >= 73) {
        _processFullState(_packetBuffer);
        _isAccumulating = false;
      }
    } else if (_isAccumulating) {
      _packetBuffer.addAll(value);
      if (_packetBuffer.length >= 73) {
        _processFullState(_packetBuffer);
        _isAccumulating = false;
      }
    } else {
      _processEventPacket(header, value, hex);
    }
  }

  void _processFullState(List<int> packet) {
    String fen = ChessProtocol.parseBoardState(packet);
    if (fen.isNotEmpty) {
      _currentFen = fen;
      _recorder.handleNewFen(fen);
      _addLog("🏁 FEN Synced: $fen", LogType.success);
      notifyListeners();
    }
  }

  void _processEventPacket(int header, List<int> value, String hex) {
    switch (header) {
      case 0xB8: // Touch
        if (value.length >= 2) {
          _liftedSquare = value[1];
          _addLog("💡 Touch: ${value[1]}", LogType.system);
        }
        break;
      case 0xBB: // Release
        _liftedSquare = null;
        _addLog("💡 Release", LogType.system);
        sendCommand("B0"); // Polling sync
        break;
      case 0xA4: // Placement
        _liftedSquare = null;
        _addLog("📍 Placement", LogType.success);
        sendCommand("B0");
        break;
      default:
        _addLog("RX: $hex", LogType.rx);
    }
    notifyListeners();
  }

  Future<void> sendCommand(String hex) async {
    if (_writeChar == null) return;
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

  void disconnect() {
    _connectedDevice?.disconnect();
    _handleDisconnect();
  }
}
