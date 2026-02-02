# ChessUp Pro Mobile

A Flutter mobile application for the ChessUp smart chessboard with advanced features including:
- 🎮 Real-time game recording and playback
- 🔄 Bluetooth connectivity with ChessUp boards
- 📊 Game library and history
- ♟️ Touch controls with visual feedback
- 🏆 Checkmate detection and automatic result tracking
- ☁️ Cloud database synchronization

## Related Projects
- 🌐 **[ChessUp Firmware Extension](https://github.com/Mrswami/chessup-firmware-extension)** - Browser-based tools and protocol reverse engineering

## Features
- **Live Game Sync**: Real-time board state monitoring via BLE
- **Auto-Save**: Graceful exit handling with automatic game saving
- **Game Library**: Browse and replay previously recorded games
- **Touch Highlighting**: Visual feedback for piece movements
- **Cloud Integration**: Firebase backend for game persistence

## Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- A ChessUp or ChessUp 2 smart chessboard
- Android/iOS device with Bluetooth support

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/Mrswami/chessup-pro-mobile.git
   cd chessup-pro-mobile
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## Development
This app communicates with ChessUp boards using Bluetooth Low Energy (BLE) protocol. See the [ChessUp Firmware Extension](https://github.com/Mrswami/chessup-firmware-extension) project for protocol documentation.

## License
MIT
