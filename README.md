# ChessUp Pro Mobile

A Flutter mobile application for the ChessUp smart chessboard.

![Build Status](https://github.com/Mrswami/chessup-pro-mobile/workflows/Build%20and%20Release%20Android%20APK/badge.svg)

## Features

✅ **Auto-Connect** - Automatically connects to your ChessUp board on startup  
✅ **Projection Mode** - Opens directly to the chess board view  
✅ **Responsive Design** - Optimized for phones, tablets, and foldables  
✅ **Game Recording** - Save games to Firebase Cloud  
✅ **Bluetooth Integration** - Real-time board state synchronization  
✅ **CI/CD Pipeline** - Automated builds and email delivery  

## Quick Start

1. Download the latest APK from [Releases](https://github.com/Mrswami/chessup-pro-mobile/releases)
2. Install on your Android device
3. Grant Bluetooth permissions
4. Open the app - it will auto-connect to your ChessUp board!

## Development

### Prerequisites
- Flutter 3.38.9+
- Dart 3.10.8+
- Android SDK

### Setup
```bash
flutter pub get
flutter run
```

### Build APK
```bash
flutter build apk --release
```

## CI/CD

Every push to `master` automatically:
- Builds a release APK
- Runs tests and analysis
- Emails the APK to the developer
- Stores artifacts for 30 days

See [CI_CD_GUIDE.md](CI_CD_GUIDE.md) for details.

## Documentation

- [Responsive Design Guide](RESPONSIVE_DESIGN.md)
- [Auto-Connect Flow](AUTO_CONNECT_GUIDE.md)
- [CI/CD Setup](CI_CD_GUIDE.md)
- [Email Setup](EMAIL_SETUP.md)

## License

Private project - All rights reserved.
