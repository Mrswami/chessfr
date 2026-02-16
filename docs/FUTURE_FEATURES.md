# Future Features & Roadster Roadmap

This document serves as a repository for high-level, advanced, or "moonshot" ideas that we plan to implement after the core product is stable.

## 3D Spectator Realm & Avatars
**Idea:** Create a 3D virtual realm where users have custom avatars.
- **Functionality:**
  - Users can customize their 3D avatar.
  - If a connected user is playing a game online (e.g., via Chess.com or Lichess), their avatar is displayed in the realm "playing" at a virtual board.
  - Other users in the realm can walk up to the avatar to spectate the game live.
  - Integration with Chess.com/Lichess console commands (e.g., `/observe "username"`) to fetch moves.
- **Technical Needs:**
  - 3D Engine integration (Unity as a library or Flutter 3D rendering like `flutter_cube` or `flame`).
  - Real-time WebSocket connection to chess platforms for move updates.
  - Multiplayer synchronization for the realm itself.

## Voice Coaching
**Idea:** Real-time voice feedback during training games.
- **Functionality:** The "Personal Trainer" speaks to you, giving hints or admonishments based on move quality.

## AR Board Overlay
**Idea:** Use the phone camera to overlay analysis on a physical chessboard.
