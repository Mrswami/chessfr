# Agent Handoff: Chess Personal Trainer

**Purpose:** Give a new agent (or developer) full context on where the project is and how to continue.

---

## 1. What This Project Is

**Chess Personal Trainer** (pattern-aligned chess coaching) is a Flutter app that teaches chess by ranking moves using **both** engine evaluation (Stockfish) and **design metrics** (connectivity between piece clusters). The goal is a "personal logic filter": recommendations that match the user's cognitive profile (Connectivity, Response, Influence) instead of only "best engine move."

- **Frontend:** Flutter (Dart), Material 3, dark theme (teal/amber).
- **Backend:** Supabase (Auth + Postgres). No separate API server.
- **Repo:** GitHub `Mrswami/ChessPersonalTrainer` (private). Default branch: `master`.

---

## 2. What’s Done

| Area | Status | Notes |
|------|--------|--------|
| **Environment** | Done | Flutter SDK; Supabase project created (ref in env). |
| **Database** | Done | Migration `001_initial_schema.sql` (profiles, positions, move_recommendations, training_sessions, user_stats, RLS, trigger). |
| **Auth** | Done | Email/password via Supabase; Auth screen; auto profile + user_stats on signup. |
| **Home** | Done | Dashboard with real Streak/XP from `user_stats`, tiles for Start Training and My Profile. |
| **Training screen** | Done | Board (flutter_chess_board), Stockfish top-3, MoveRanker + DesignMetrics, ranked list, feedback, XP. |
| **Chess logic** | Done | Stockfish integrated; MoveRanker; Game Analysis (Swing Spots); PGN import. |
| **Opening Explorer** | Done | Lichess Masters integration to show opening name, ECO, and play count in Training. |
| **Training loop** | Done | On move: resolve profile + position, compute outcome/XP, insert `training_sessions`, update `user_stats`. |
| **Analysis** | Done | Import/Paste PGN, detect Swing Spots, navigate to training. |
| **UI/theme** | Done | AppTheme (teal/amber), polished Auth/Home/Training/Admin. |
| **Admin** | Done | Admin Dashboard (user management). |
| **Firebase** | Setup | `FIREBASE_SETUP.md` created. App Distribution configured for "email myself" tester workflow. |
| **CI/CD** | Done | `.github/workflows/ci.yml` (analyze/test) & `deploy.yml` (Web -> Pages) configured. |

---

## 3. What’s Not Done (Next Steps)

- **Firebase Config:** Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) and place in respective folders.
- **Admin Backend:** Admin dashboard currently uses mock data; add RLS policies for admin-only tables.
- **Profile screen:** “My Profile” tile doesn’t navigate yet; cognitive weights are hardcoded.
- **Next position / sessions:** Manual back navigation only; no "Next puzzle" flow.
- **Real ads / IAP:** Loading ad is a placeholder.

---

## 4. Key Files and Layout

```
ChessPersonalTrainer/
├── .github/workflows/
│   ├── ci.yml          # CI: analyze + test
│   └── deploy.yml      # CD: Flutter web → GitHub Pages
├── backend/
│   ├── .env.example    # SUPABASE_URL, SUPABASE_ANON_KEY
│   └── supabase/migrations/
├── docs/
│   ├── AGENT_HANDOFF.md     # This file
│   ├── FIREBASE_SETUP.md    # Guide for notifications and App Distribution
│   ├── PROJECT_OVERVIEW.md
│   ├── PROTOCOL_AND_STATUS.md
│   ├── TRAINING_LOOP.md
│   ├── DATA_MODEL.md
│   └── REVENUE_STRATEGIES.md
├── flutter/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── core/theme.dart
│   │   └── features/
│   │       ├── auth/auth_screen.dart
│   │       ├── home/home_screen.dart
│   │       ├── training/training_screen.dart, training_repository.dart
│   │       ├── logic/design_metrics.dart, move_ranker.dart, stockfish_service.dart, opening_service.dart
│   │       └── monetization/loading_ad_screen.dart
│   └── pubspec.yaml
└── README.md
```

---

## 5. How to Run Locally

1. **Supabase:** Ensure migrations are run in the project’s SQL Editor.
2. **Flutter:** `cd flutter`, `flutter pub get`, `flutter run`.
3. **Auth:** Sign up in app.

---

## 6. GitHub Pages: Exact Clicks

1. **Settings** -> **Pages**.
2. **Source:** **“GitHub Actions”**.
3. Push to `master` triggers deploy to `https://mrswami.github.io/ChessPersonalTrainer`.

---

## 7. Environment / Secrets

- **Supabase:** Keys in `main.dart`. Use env for production.

---

## 8. Docs to Read for Deeper Context

- **Setup & Testers:** `docs/FIREBASE_SETUP.md` (Crucial for "email myself" workflow)
- **Product / concepts:** `docs/PROJECT_OVERVIEW.md`
- **Protocol:** `docs/PROTOCOL_AND_STATUS.md`

---

## 9. One-Line Summary for a New Agent

**Flutter + Supabase app for pattern-aligned chess coaching: auth, home with Streak/XP, training screen with board + ranked moves + OP explorer, stockfish logic, swing spot analysis, and persisted stats. Deploy is GitHub Actions. Firebase App Distribution is used for testing.**

---

## 10. PINNED THOUGHTS (DISTANT FUTURE)

**Strategic Ideas & Deferred Features:**

1.  **Visual Overhaul (Eerie/Modern):**
    *   *Concept:* Update the app image/icon from "Santa with whitened eyes" to a "Sleek/Modern Magnus Carlsen with a tinge of eeriness."
    *   *Action:* Use `generate_image` or external tools when tokens/budget allow.

2.  **Session Connectivity (Flow):**
    *   *Concept:* Reduce friction by implementing a "Next Puzzle" button or automatic transition after a solved position, instead of forcing manual back navigation.
    *   *Goal:* Keep the user in the "flow state" longer.

3.  **Admin & Security Hardening:**
    *   *Concept:* The Admin Dashboard is currently frontend-only. We need strict RLS policies (e.g., `is_admin` column in profiles) to secure user management endpoints.

4.  **Monetization Construction:**
    *   *Concept:* Replace the placeholder "Loading Ad" screen with real AdMob integration and In-App Purchases (IAP) for "Premium" removal of ads.

5.  **Dynamic Cognitive Profile:**
    *   *Concept:* The "My Profile" weights (Connectivity vs. Material) are currently hardcoded. These should dynamically adjust based on user performance in specific puzzle types.

