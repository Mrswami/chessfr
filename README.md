# ♟️ Chess XL: Personal Trainer 🎅🐟

**Chess XL** is a next-generation chess training application that moves beyond raw engine evaluations. It introduces the **DankFish Personalized Logic Filter**, which ranks moves based on your unique cognitive strengths—balancing structural connectivity, piece influence, and response accuracy.

---

## 🌟 Key Features

### 🧠 Personalized Training (DankFish)
- **Engine vs. Design**: Toggle between pure **Stockfish** analysis and **DankFish Mode**.
- **Cognitive Weights**: The app adapts to your playstyle by weighing connectivity, response, and influence metrics.
- **Delta-V Logic**: Accepts minor evaluation losses in exchange for significantly clearer board structures.

### 🎅 Customization & Social
- **Santa Avatar System**: Choose from 8 unique Santa variants including **Ninja**, **Robot**, **King**, and **Space Santa**.
- **High-End Themes**: 8 premium background gradients (Fire, Gold, Arctic, etc.).
- **Profile Snapshots**: Capture and share your custom avatar and stats (XP, Streaks) directly to social media.
- **Global Leaderboard**: Compete against players worldwide on a real-time animated podium.

### 🔧 Secret Developer Tools
- **Hidden Admin Panel**: Accessible via a secret 5-tap gesture with haptic feedback.
- **Quick Switch**: Instant login as Admin, Free, or Premium users for testing.
- **Stats Editor**: Real-time manipulation of XP and Streaks for development.

### 📡 Advanced Integration
- **Chess Vision**: Scan real boards using an optical neural network (Camera Integration).
- **Hardwire Sync**: Connect directly to **ChessUp** hardware via Bluetooth.
- **Auto-Sync**: Seamless synchronization with **Supabase** cloud backend.

---

## 🛠️ Technology Stack

| Component | Technology |
| :--- | :--- |
| **Frontend** | Flutter (Multi-platform) |
| **Backend** | Supabase (PostgreSQL, Auth, RLS) |
| **Animation** | Flutter Animate (Physics-based UI) |
| **CI/CD** | GitHub Actions + Firebase App Distribution |
| **Chess Engine** | Stockfish (Local WASM/Native) |

---

## 🚀 Development Setup

### Prerequisites
- Flutter SDK (Latest Stable)
- Supabase Project (Tables: `profiles`, `user_stats`, `positions`, `training_sessions`)

### Commands
```bash
# Clone the repository
git clone https://github.com/Mrswami/ChessPersonalTrainer

# Install Flutter dependencies
cd flutter
flutter pub get

# Run the app
flutter run
```

---

## 🤖 CI/CD Pipeline
Every push to `master` automatically:
1. Runs full static code analysis (Lints).
2. Executes unit tests.
3. Builds a fat Android APK.
4. Distributes the build to **Firebase App Distribution** for beta testing.

---

## 📜 License
*Designed and built with ♟️ by the Chess XL Team.*
