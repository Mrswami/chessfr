# ChessUp Pro Mobile - Development Guide

> **Project Goal**: Create a Flutter mobile app that connects to a ChessUp Pro electronic chess board via Bluetooth Low Energy (BLE), reads piece positions in real-time, and projects the game state onto a larger screen for broadcast/streaming purposes.

---

## 📐 Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      Flutter App                            │
├─────────────────────────────────────────────────────────────┤
│  main.dart          │  game_screen.dart  │  chess_protocol  │
│  ─────────────────  │  ────────────────  │  ───────────────│
│  • BLE Scanning     │  • Board UI        │  • Packet Parser │
│  • Connection Mgmt  │  • Piece Rendering │  • FEN Generator │
│  • Event Handling   │  • Flip/Rotate     │  • Byte→Piece    │
│  • State Management │  • Debug Overlay   │    Mapping       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  ChessUp Pro Hardware                        │
│  Nordic UART Service (NUS) - 6e400001-b5a3-f393-e0a9-...    │
│  ─────────────────────────────────────────────────────────  │
│  • TX Char: 6e400002 (Write commands to board)              │
│  • RX Char: 6e400003 (Receive events from board)            │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔌 BLE Protocol Discoveries

### Service & Characteristics
| UUID | Purpose |
|------|---------|
| `6e400001-b5a3-f393-e0a9-e50e24dcca9e` | Nordic UART Service |
| `6e400002-b5a3-f393-e0a9-e50e24dcca9e` | Write (TX) - Send commands |
| `6e400003-b5a3-f393-e0a9-e50e24dcca9e` | Notify (RX) - Receive events |

### Packet Types
| Prefix | Meaning | Notes |
|--------|---------|-------|
| `0xE9` | Piece Event | Lift/Place detection |
| `0x71` | Board State Dump | Full 64-square snapshot |
| `0xB2` | Status Report | Connection health |
| `0x26` | Error/NACK | Command rejected |
| `0xBB` | Heartbeat | Keep-alive |

### E9 Packet Structure (Piece Events)
```
E9 [ActionByte] [??]

ActionByte = SquareID (bits 0-5) + ActionFlag (bit 6)

- Bit 6 SET (0x40):   LIFTED (piece picked up)
- Bit 6 CLEAR:        PLACED (piece put down)
- Bits 0-5:           Hardware Square ID (0-63 in 12-wide grid)
```

### 12-Wide Hardware Grid
The ChessUp Pro uses a **12-column internal grid** (not 8). This means:
```dart
int _chessUpToIndex(int hardwareSq) {
  int rank = hardwareSq ~/ 12;  // Row
  int file = hardwareSq % 12;   // Column
  
  if (rank >= 0 && rank < 8 && file >= 0 && file < 8) {
    return rank * 8 + file;  // Convert to 0-63 standard index
  }
  return -1;
}
```

**Example**: Hardware ID `40` → Rank 3, File 4 → Square `e4` ✓

---

## 🗂️ File Structure

```
chessup_pro_mobile/
├── lib/
│   ├── main.dart           # Entry point, BLE logic, state management
│   ├── game_screen.dart    # Projection UI with visual board
│   └── chess_protocol.dart # Packet parsing and piece mapping
├── android/
│   └── app/src/main/
│       ├── AndroidManifest.xml  # BLE permissions
│       └── res/mipmap-*/        # App icons
├── pubspec.yaml            # Dependencies
└── DEVELOPMENT_GUIDE.md    # This file
```

---

## 📦 Key Dependencies

```yaml
dependencies:
  flutter_blue_plus: ^1.31.13   # BLE communication
  permission_handler: ^11.0.1   # Runtime permissions
  shared_preferences: ^2.2.2    # Persist last device ID
  google_fonts: ^6.1.0          # Typography
```

---

## 🧠 State Management Pattern

We use a simple **StatefulWidget** pattern with the following state variables:

```dart
class _ScanningScreenState extends State<ScanningScreen> {
  // BLE State
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeChar;
  String? _autoConnectId;
  
  // Board State
  static const String _startingFen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR";
  String _currentFen = _startingFen;
  int? _liftedSquare;  // Currently lifted piece's hardware ID
  bool _showProjection = false;
  
  // Logs
  final List<LogEntry> _logs = [];
}
```

### Why No Provider/Bloc?
For a focused, single-screen app with limited state complexity, a StatefulWidget is:
- Faster to iterate
- Easier to debug
- Sufficient for real-time BLE event handling

---

## 🔄 Event Flow

```
1. User lifts piece (e2)
   ↓
2. Board sends: E9 68 00
   ↓
3. _handlePacket() parses:
   - rawByte = 0x68
   - isLifted = (0x68 & 0x40) != 0 → TRUE
   - hardwareSq = 0x68 & 0x3F → 0x28 (40)
   - _chessUpToIndex(40) → 12 (e2)
   ↓
4. _liftedSquare = 40
   ↓
5. User places piece (e4)
   ↓
6. Board sends: E9 28 00
   ↓
7. _handlePacket() parses:
   - isLifted = FALSE (0x28 & 0x40 = 0)
   - hardwareSq = 0x28 (40 again, but it's e4 due to the 12-wide math)
   ↓
8. _applyMove(fromIndex, toIndex)
   ↓
9. setState() → UI rebuilds with updated FEN
```

---

## 🎨 UI Components

### ScanningScreen (main.dart)
- **Scanner View**: Lists nearby ChessUp devices
- **Control Panel**: Debug console, hex command input, quick buttons
- **Projection Toggle**: "SHOW BOARD" button

### GameProjectionScreen (game_screen.dart)
- **Visual Board**: 8x8 grid with pieces
- **Flip Toggle**: Rotate board 180°
- **Debug Sidebar**: Live packet log
- **Pickup Indicator**: Shows currently lifted piece

---

## 🐛 Debugging Tips

### 1. Check Raw Packets
All packets are logged to both the UI and console:
```dart
print("📦 RAW PACKET: $hex (${value.length} bytes)");
```

### 2. Verify Coordinate Mapping
If pieces move to wrong squares, check:
- Is the 12-wide stride correct?
- Is the bit mask (0x3F) extracting the right ID?

### 3. FEN Validation
Invalid FEN will show as `?` pieces. Check `ChessProtocol._byteToPiece()`.

---

## 🚀 Build & Run

```bash
# Install dependencies
flutter pub get

# Run on connected device
flutter run

# Build release APK
flutter build apk --release
```

---

## 📋 Known Protocol Commands

| Hex | Description |
|-----|-------------|
| `71 01` | Request board state (partial success) |
| `40 00` | Force start session (unverified) |
| `EF 01` | Reset board (unverified) |

---

## 🔮 Future Enhancements

1. **Chromecast/AirPlay Support**: Wireless TV projection
2. **Move History Sidebar**: PGN-style notation
3. **Clock Integration**: Display remaining time
4. **SVG Piece Assets**: Higher quality than Unicode
5. **Sound Effects**: Audio feedback on moves

---

## 📝 Lessons Learned

1. **Hardware protocols are rarely documented** — Use packet sniffing and trial/error.
2. **Bit manipulation is essential** — Flags are often packed into single bytes.
3. **12-wide grids exist** — Don't assume 8x8 for physical board hardware.
4. **Start with a known position** — Don't depend on unreliable sync commands.
5. **Event-driven > Polling** — Track moves incrementally for real-time UX.

---

*Last Updated: January 26, 2026*
