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
| **Database** | Done | Migration `001_initial_schema.sql` (profiles, positions, move_recommendations, training_sessions, user_stats, RLS, trigger). Run in Supabase SQL Editor. Also run `002_positions_insert_policy.sql` so app can insert new positions. |
| **Auth** | Done | Email/password via Supabase; Auth screen; auto profile + user_stats on signup. |
| **Home** | Done | Dashboard with real Streak/XP from `user_stats`, tiles for Start Training and My Profile. |
| **Training screen** | Done | Board (flutter_chess_board), mock Stockfish top-3, MoveRanker + DesignMetrics, ranked list, feedback, XP in message. |
| **Training loop (persist)** | Done | On move: resolve profile_id + position_id, compute outcome + latency + XP, insert `training_sessions`, update `user_stats`. Home refreshes stats when returning from Training. |
| **Chess logic** | Partial | MoveRanker and DesignMetrics in Dart; **Stockfish is mocked** (returns fixed moves). Real engine (API or Edge Function) not wired. |
| **UI/theme** | Done | AppTheme (teal/amber), polished Auth/Home/Training, loading ad placeholder. |
| **CI** | Done | `.github/workflows/ci.yml`: `flutter analyze` + `flutter test` on push/PR. |
| **CD** | Done | `.github/workflows/deploy.yml`: build Flutter web, upload artifact, deploy to GitHub Pages. **Pages must use “GitHub Actions” as source** (see below). |

---

## 3. What’s Not Done (Next Steps)

- **Stockfish:** Replace mock in `lib/features/logic/stockfish_service.dart` with real engine (e.g. Stockfish API, WASM, or Supabase Edge Function).
- **Profile screen:** “My Profile” tile doesn’t navigate yet; cognitive weights (connectivity_weight, engine_trust) are hardcoded in Training.
- **Load profile from DB:** Training uses mock profile map; could fetch `profiles.cognitive_profile` and pass to MoveRanker.
- **Next position / sessions:** After one move, user goes back manually; no “Next puzzle” or “session of N positions” yet.
- **Real ads / IAP:** Loading ad is a placeholder; no ad SDK or in-app purchase.
- **Supabase CD:** Optional job in `deploy.yml` to run `supabase db push` is commented out; add secrets and uncomment if you want migrations on deploy.

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
│       ├── 001_initial_schema.sql
│       └── 002_positions_insert_policy.sql
├── docs/
│   ├── AGENT_HANDOFF.md     # This file
│   ├── PROJECT_OVERVIEW.md  # Product concepts
│   ├── PROTOCOL_AND_STATUS.md
│   ├── TRAINING_LOOP.md      # Training loop context + implementation
│   ├── DATA_MODEL.md
│   └── REVENUE_STRATEGIES.md
├── flutter/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── core/theme.dart, constants.dart
│   │   └── features/
│   │       ├── auth/auth_screen.dart
│   │       ├── home/home_screen.dart
│   │       ├── training/training_screen.dart, training_repository.dart
│   │       ├── logic/design_metrics.dart, move_ranker.dart, stockfish_service.dart
│   │       └── monetization/loading_ad_screen.dart
│   └── pubspec.yaml
├── data/sample_move_payload.json
└── README.md
```

- **Supabase config:** URL and anon key are in `flutter/lib/main.dart` (move to env or --dart-define for production).
- **Training persistence:** `TrainingRepository` talks to `training_sessions` and `user_stats`; used by `TrainingScreen` and `HomeScreen`.

---

## 5. How to Run Locally

1. **Supabase:** Ensure migrations `001` and `002` are run in the project’s SQL Editor.
2. **Flutter:** From repo root, `cd flutter` then `flutter pub get` and `flutter run` (pick device: Windows, Chrome, Android, etc.).
3. **Auth:** Sign up with email/password in the app; profile and user_stats are created by DB trigger.

---

## 6. GitHub Pages: Exact Clicks (No “Deploy from a branch”)

We deploy via **GitHub Actions**, not “Deploy from a branch.” Use these steps:

1. Open the repo: **https://github.com/Mrswami/ChessPersonalTrainer**
2. Click the **Settings** tab (top bar of the repo).
3. In the **left sidebar**, under **“Code and automation”**, click **Pages**.
4. Under **“Build and deployment”**:
   - **Source:** select **“GitHub Actions”** (not “Deploy from a branch”).
5. Save if there’s a button. You do **not** need to choose a branch; the workflow in `.github/workflows/deploy.yml` runs on push to `master`/`main`.
6. Push to `master` (or run the workflow manually: Actions → Deploy → Run workflow). After it succeeds, the **Pages** page will show **“Your site is live at https://mrswami.github.io/ChessPersonalTrainer”** (or the org/user equivalent). That URL is the **domain** for the app.

If **Settings** or **Pages** is missing, the account may not have admin access to the repo.

---

## 7. Environment / Secrets

- **Supabase:** Project URL and anon key are in `main.dart`. For CI/CD or production, use env or `--dart-define` and avoid committing keys.
- **Optional Supabase CD:** To run `supabase db push` in GitHub Actions, add repo secrets `SUPABASE_ACCESS_TOKEN` and `SUPABASE_PROJECT_REF`, then uncomment the `supabase-migrate` job in `deploy.yml`.

---

## 8. Docs to Read for Deeper Context

- **Product / concepts:** `docs/PROJECT_OVERVIEW.md`
- **Protocol, plan status, why Supabase/CI:** `docs/PROTOCOL_AND_STATUS.md`
- **Training loop (conversation + implementation):** `docs/TRAINING_LOOP.md`
- **Schema:** `docs/DATA_MODEL.md`

---

## 9. One-Line Summary for a New Agent

**Flutter + Supabase app for pattern-aligned chess coaching: auth, home with Streak/XP, training screen with board + ranked moves and full persist to `training_sessions` and `user_stats`. Stockfish is mocked; profile screen and “next position” not built. Deploy is GitHub Actions → GitHub Pages (source = GitHub Actions).**
