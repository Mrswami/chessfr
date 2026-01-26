import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChessUp Pro RE',
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
  
  // Research State
  final List<LogEntry> _logs = [];
  final TextEditingController _hexController = TextEditingController();
  final ScrollController _logScroll = ScrollController();

  // Constants
  final String serviceUuid = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
  final String chWriteUuid = "6e400002-b5a3-f393-e0a9-e50e24dcca9e";
  final String chReadUuid = "6e400003-b5a3-f393-e0a9-e50e24dcca9e";

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
    _startScan(); // Auto-start scan on launch
  }

  void _addLog(String text, LogType type) {
    if (!mounted) return;
    setState(() {
      _logs.insert(0, LogEntry(timestamp: DateTime.now(), text: text, type: type));
      if (_logs.length > 200) _logs.removeLast(); // Keep history manageable
    });
    // Also print to console so the AI can read it via terminal
    print("[${type.name.toUpperCase()}] $text");
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _scanResults = [];
    });
    _addLog("Scanning for ChessUp...", LogType.system);

    try {
      // Filter is tricky on some Androids, so we scan all and filter in list
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    } catch (e) {
      _addLog("Scan Error: $e", LogType.error);
    }

    FlutterBluePlus.scanResults.listen((results) {
      if (mounted) {
        setState(() {
          // FILTER: Only show devices connected or with "Chess" in name
          _scanResults = results.where((r) {
            String name = r.device.platformName;
            return name.toLowerCase().contains("chess");
          }).toList();
        });
      }
    });

    FlutterBluePlus.isScanning.listen((scanning) {
      if (mounted) {
        setState(() => _isScanning = scanning);
      }
    });
  }

  Future<void> _connect(BluetoothDevice device) async {
    _addLog("Connecting to ${device.platformName}...", LogType.system);
    try {
      await device.connect(autoConnect: false);
      _addLog("Connected! Discovering services...", LogType.system);
      
      List<BluetoothService> services = await device.discoverServices();
      bool found = false;

      for (var service in services) {
        if (service.uuid.toString() == serviceUuid) {
          found = true;
          for (var c in service.characteristics) {
            if (c.uuid.toString() == chWriteUuid) {
              _writeChar = c;
              _addLog("Write Channel Open 🟢", LogType.success);
            }
            if (c.uuid.toString() == chReadUuid) {
              _addLog("Notifier Hooked 🔵", LogType.success);
              await c.setNotifyValue(true);
              c.lastValueStream.listen((value) => _handlePacket(value));
            }
          }
        }
      }

      if (found) {
        setState(() => _connectedDevice = device);
      } else {
        _addLog("Error: ChessUp Service not found!", LogType.error);
        device.disconnect();
      }

    } catch (e) {
      _addLog("Connection failed: $e", LogType.error);
    }
  }

  // THE BRAIN: Decodes packets in real-time
  void _handlePacket(List<int> value) {
    String hex = value.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    
    String meaning = "";
    LogType type = LogType.rx;

    if (hex.startsWith("b2")) {
        meaning = "[Status Report]";
    }
    else if (hex.startsWith("26")) {
        meaning = "[Error/NACK]";
        type = LogType.error;
    }
    else if (hex.startsWith("e9")) {
        // [Command] [SourceSq] [DestSq?] ...
        int sq = value.length > 1 ? value[1] : 0;
        int rank = sq ~/ 8;
        int file = sq % 8;
        String alg = "${String.fromCharCode('a'.codeUnitAt(0) + file)}${rank + 1}";
        meaning = "[Piece Event] $alg ($sq)";
    }
    else if (hex.startsWith("71")) {
        meaning = "[Board State Dump]";
    } 
    // NEW: Catch-all for interesting unknown packets
    else {
        meaning = "🔥🔥 UNKNOWN/INTERESTING 🔥🔥";
        type = LogType.success; // Use Green to highlight
    }

    _addLog("RX: $hex $meaning", type);
  }

  Future<void> _sendCommand(String hex) async {
    if (_connectedDevice == null || _writeChar == null) {
      _addLog("Not connected", LogType.error);
      return;
    }
    
    // Cleanup input
    hex = hex.replaceAll(" ", "").toLowerCase();
    
    List<int> bytes = [];
    try {
      for (int i = 0; i < hex.length; i += 2) {
        bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
      }
      await _writeChar!.write(bytes);
      _addLog("TX: $hex", LogType.tx);
    } catch (e) {
      _addLog("TX Error: $e", LogType.error);
    }
  }

  bool _isBruteForcing = false;
  String? _lastSent;
  String? _crashCommand;
  // Captured from btsnoop_hci.log
  final TextEditingController _fuzzStartController = TextEditingController(text: "50");
  final TextEditingController _fuzzSuffixController = TextEditingController(text: "00");
  
  final List<String> _capturedCommands = [
    "121600192A", // Init/Version?
    "40000000",   // Start Game Mode?
    "1E5555555555555550", // Setup Grid?
    "3503010303", // Highlights?
    "3504060405",
    "3506070505",
    "1C55555555555555",
    "24555555555555555555",
  ];

  Future<void> _replayLog() async {
     _addLog("Replaying Captured Sequence...", LogType.system);
     for (String cmd in _capturedCommands) {
        if (_connectedDevice == null) break;
        await _sendCommand(cmd);
        // Wait 300ms between commands to let board digest
        await Future.delayed(const Duration(milliseconds: 300));
     }
     _addLog("Replay Complete.", LogType.system);
  }

  Future<void> _bruteForceScan() async {
    // ... (Existing implementation, skipped for brevity in diff)
    // Reference original code for full implementation if needed
    setState(() {
         _isBruteForcing = true;
         _crashCommand = null;
    });
    
    int start = int.tryParse(_fuzzStartController.text, radix: 16) ?? 0;
    String suffix = _fuzzSuffixController.text.replaceAll(" ", "");
    
    _addLog("Fuzzing $start..FF + Suffix '$suffix'...", LogType.system);
    
    for (int i = start; i < 0xFF; i++) {
        if (!_isBruteForcing) break;
        if (_connectedDevice == null) {
            break;
        }

        // SAFETY: Skip known crash zone 60-6F
        if (i >= 0x60 && i <= 0x6F) {
            continue;
        }

        String cmd = i.toRadixString(16).padLeft(2, '0');
        if (["b2", "e9", "71", "ef", "26"].contains(cmd)) continue;
        
        String fullPacket = cmd + suffix;
        setState(() => _lastSent = fullPacket);
        await _sendCommand(fullPacket);
        await Future.delayed(const Duration(milliseconds: 200));
    }
    
    if (_isBruteForcing) {
        setState(() => _isBruteForcing = false);
        _addLog("Scan Complete.", LogType.system);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_connectedDevice != null) return _buildControlPanel();
    return _buildScanner();
  }

  Widget _buildScanner() {
    return Scaffold(
      appBar: AppBar(title: const Text("ChessUp Pro Finder")),
      floatingActionButton: FloatingActionButton(
        onPressed: _isScanning ? null : _startScan,
        backgroundColor: _isScanning ? Colors.grey : const Color(0xFF6C22F5),
        child: Icon(_isScanning ? Icons.hourglass_top : Icons.search),
      ),
      body: _scanResults.isEmpty 
        ? Center(child: Text(_isScanning ? "Scanning..." : "No ChessUp found."))
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
          // 1. Dashboard
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.black26,
            child: Column(
                children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _QuickBtn("Config (B2)", "b20004"),
                        _QuickBtn("State (71)", "7101"),
                        _QuickBtn("Reset (EF)", "ef01"),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // LED TEST ROW
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _QuickBtn("LED 1", "500C01"), // Try CMD 50 + Square + On
                        _QuickBtn("LED 2", "550C01"), // Try CMD 55
                        _QuickBtn("LED 3", "210C01"), // Try CMD 21
                      ],
                    ),
                    const SizedBox(height: 8),
                    const SizedBox(height: 8),
                     SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: _isBruteForcing ? Colors.red : Colors.amber,
                                foregroundColor: Colors.black,
                            ),
                            icon: Icon(_isBruteForcing ? Icons.stop : Icons.radar),
                            label: Text(_isBruteForcing ? "STOP SCAN" : "AUTO-SCAN PROTOCOLS"),
                            onPressed: () {
                                if (_isBruteForcing) {
                                    setState(() => _isBruteForcing = false);
                                } else {
                                    _bruteForceScan();
                                }
                            },
                        ),
                     ),
                ],
            ),
          ),
          
          // 2. Fuzzing Controls
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey[900],
            child: Column(
              children: [
                 Text("Last Sent: ${_lastSent ?? 'None'}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.amber)),
                 if (_crashCommand != null) 
                    Text("CRASHED AT: $_crashCommand", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
                 Row(
                   children: [
                     Expanded(child: TextField(
                       controller: _fuzzStartController, 
                       decoration: const InputDecoration(labelText: "Start (50)", isDense: true),
                     )),
                     const SizedBox(width: 4),
                     Expanded(child: TextField(
                       controller: _fuzzSuffixController, 
                       decoration: const InputDecoration(labelText: "Suffix (00)", isDense: true),
                     )),
                     const SizedBox(width: 8),
                     ElevatedButton(
                       onPressed: _isBruteForcing ? () => setState(() => _isBruteForcing = false) : _bruteForceScan,
                       style: ElevatedButton.styleFrom(backgroundColor: _isBruteForcing ? Colors.red : Colors.green),
                       child: Text(_isBruteForcing ? "STOP" : "FUZZ"),
                     ),
                     const SizedBox(width: 8),
                     ElevatedButton(
                        onPressed: _replayLog,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                        child: const Text("REPLAY LOG"),
                     )
                   ],
                 )
              ],
            ),
          ),
          
          // 3. Manual Input
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _hexController,
                    decoration: const InputDecoration(
                      labelText: "Raw Hex Packet",
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (val) => _sendCommand(val),
                  ),
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

          // 3. Logger
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
                    "${log.timestamp.second}:${log.timestamp.millisecond} ${log.text}",
                    style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 13),
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
        padding: const EdgeInsets.symmetric(horizontal: 12),
        minimumSize: const Size(0, 36),
      ),
      onPressed: () => _sendCommand(cmd),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

enum LogType { system, rx, tx, error, success }

class LogEntry {
  final DateTime timestamp;
  final String text;
  final LogType type;
  LogEntry({required this.timestamp, required this.text, required this.type});
}
