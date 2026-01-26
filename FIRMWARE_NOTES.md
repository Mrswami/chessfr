# ChessUp Pro Firmware Compatibility Notes

## Known Working States

### Last Known Good Configuration
- **Date**: January 26, 2026
- **Firmware**: Pre-update version (unknown exact version)
- **App Version**: commit 9a9f19c
- **Issue**: Board occasionally freezes and requires firmware update to unfreeze

---

## Critical Protocol Discoveries

### E9 Packet Format - PIECE IDs NOT Square Coordinates
**IMPORTANT**: E9 packets do NOT send square positions!

```
Format: E9 [ActionByte] [??]
ActionByte = PieceID (bits 0-5) + ActionFlag (bit 6)

Example:
E9 47 00 = Piece ID 7 lifted (bit 6 SET)
E9 28 00 = Piece ID 40 placed (bit 6 CLEAR)
```

**This means:**
- We CANNOT track moves by watching E9 packets alone
- We MUST use 0x67 or 0x71 to get actual board state
- After each piece placement, request fresh board state

### Working Packet Types
| Packet | Purpose | Reliability |
|--------|---------|-------------|
| 0x71 | Board state dump | ✅ Works reliably |
| 0xE9 | Piece event (ID only) | ✅ Detects movement but not location |
| 0x67 | Board state response | ⚠️ Format unclear |
| 0xB2 | Status report | ✅ Connection health |
| 0xBB | Heartbeat | ✅ Keep-alive |

### Coordinate System
- **Physical board**: 12-column internal grid
- **Standard chess**: 8x8 grid (a1-h8)
- **Conversion**: `rank = hwID / 12, file = hwID % 12`

---

## Firmware Update Protocol

### When to Update
- Board freezes and stops sending E9 events
- Pieces don't register when moved
- Reset doesn't fix it

### How to Update
**WARNING**: Requires ChessUp mobile app - no CLI method found

1. Open official ChessUp app
2. Connect to board
3. Settings → Firmware Update
4. Wait 5-10 minutes

### Risks
- May change BLE protocol slightly
- May change packet formats
- Unknown if reversible

### Mitigation
- Document all packet captures before and after
- Test basic connectivity immediately after
- Keep DEVELOPMENT_GUIDE.md updated

---

## Future-Proofing Strategy

### Defensive Coding
```dart
// Always check packet lengths
if (value.length < expectedBytes) return;

// Always validate piece IDs
if (!('pnbrqkPNBRQK'.contains(pieceCode))) return;

// Always handle unknown packets gracefully
else {
  _addLog("Unknown packet: $hex", LogType.rx);
}
```

### Fallback Mode
If BLE protocol breaks:
1. Use periodic polling (request 0x71 every 500ms)
2. Compare FEN strings to detect changes
3. Don't rely on E9 events

---

## Testing Checklist After Update

- [ ] Board connects via BLE
- [ ] E9 packets sent when piece lifted/placed
- [ ] 0x71 packet returns valid FEN
- [ ] Pieces register on correct squares
- [ ] No random rooks/pieces appearing
- [ ] App doesn't crash on unknown packets

---

*Last Updated: January 26, 2026 11:12 AM*
