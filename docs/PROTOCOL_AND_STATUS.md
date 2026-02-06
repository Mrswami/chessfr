# Protocol, Plan Status, and Why We Use Supabase + CI/CD

## 1. Protocol (How the System Works)

**Protocol** here means: how data and control flow between the user, the app, and the backend so the product does what you want.

### High-level flow

```
User opens app
    → (optional) Loading ad screen
    → Auth: sign in/up via Supabase Auth
    → Home: see Streak/XP, tap "Start Training"
    → Training: load position (FEN), get engine top moves, rank by design metrics, show board + ranked list
    → User makes move → feedback + (future) log to training_sessions in Supabase
```

### Data protocol

| Layer | Responsibility |
|-------|----------------|
| **Flutter app** | UI, auth state, call Supabase (auth + REST/Realtime), run ranking logic (Stockfish mock + MoveRanker). |
| **Supabase** | Auth (who the user is), Postgres (profiles, positions, move_recommendations, training_sessions, user_stats), optional Edge Functions later. |
| **Chess logic** | Engine top-N (currently mocked in Dart; later Stockfish API or Edge Function), design metrics (connectivity/islands), MoveRanker combines engine + profile weights. |

### API surface (Supabase)

- **Auth**: `signUp`, `signInWithPassword`, `signOut`, `onAuthStateChange`.
- **Database**: Tables are accessed via PostgREST (auto-generated from your schema). Flutter uses `Supabase.instance.client.from('profiles')`, etc. No custom REST API to maintain—Supabase gives you the API from the schema.
- **Future**: Edge Functions can run Stockfish or heavy analytics server-side; you’d call them via `Supabase.instance.client.functions.invoke('name')`.

So the **protocol** is: **Flutter ↔ Supabase (Auth + Postgres + later Functions)**. No separate “backend server” to run or host—Supabase is the backend.

---

## 2. Where We Are in the Plan (LAN = Plan)

Using the original roadmap as the “plan”:

| Phase | Status | What’s done |
|-------|--------|-------------|
| **0 – Environment** | Done | Flutter installed; Supabase account + project created. |
| **1 – Backend** | Done | Migration SQL written (`backend/supabase/migrations/001_initial_schema.sql`). You run it in Supabase Dashboard SQL Editor; Auth + RLS included. |
| **2 – Flutter shell** | Done | App created; Supabase init in `main.dart`; Auth screen, Home, Training screen; theme and UI polish. |
| **3 – Chess logic** | In progress | MoveRanker + DesignMetrics in Dart; Stockfish currently **mocked** (returns fixed top-3). Real engine still to plug in (e.g. Stockfish API or Edge Function). |
| **4 – Training loop** | In progress | Board + ranked moves + feedback work; **logging to `training_sessions` and updating `user_stats` not yet wired** from the app. |
| **5 – Polish + revenue** | Started | Duolingo-style UI; loading ad placeholder. No real ad SDK or in-app purchase yet. |

So: **we’re past the foundation (Phases 0–2), in the middle of logic and training loop (3–4), with initial polish (5).** Next concrete steps: wire training sessions to Supabase, then add real Stockfish (or API) and optional CI/CD.

---

## 3. Why Supabase Is the Right Fit (Industry Standard for This Use Case)

What you’re building: a **solo/small-team**, **user-facing app** with **auth**, **structured data**, and **optional server-side logic** later. For that, the “industry standard” pattern is: **BaaS (Backend-as-a-Service)** or **managed Postgres + Auth**, not a custom server from scratch.

### Why Supabase in particular

1. **One place for auth + database**
   - Auth (email, magic link, OAuth) and Postgres live together. No separate auth server or sync. Flutter talks to one backend.
   - Your schema (profiles, positions, training_sessions, etc.) is normal SQL; you get a **REST and Realtime API** from the schema. That’s the standard for apps that need both “user accounts” and “tables.”

2. **SQL-first and scalable**
   - You keep full control with SQL (migrations, RLS, functions). When you need “complex analytics” or “design metrics over many sessions,” you can do it in Postgres (views, functions) or later in Edge Functions. That’s why it’s considered “industry standard” for data-heavy or analytics-heavy products—you’re not locked into a no-SQL-only store.

3. **Security by default**
   - Row Level Security (RLS) means: “users only see their own rows.” The migration we added enforces that. So from day one you’re following the standard pattern: **auth identity + RLS = secure multi-tenant data**.

4. **Cost and ops**
   - Free tier is enough for hundreds of users. You don’t run servers, scale Postgres, or build an API layer—Supabase does. For a solo dev or small team, that’s exactly the standard approach: **ship fast, scale when needed**.

5. **Ecosystem**
   - Flutter has first-class Supabase clients; Supabase is widely used and documented. So “Flutter + Supabase” is a common, industry-standard stack for apps like yours.

**In one line:** Supabase is the right choice because it gives you **auth + Postgres + optional server logic** in one place, with **SQL and RLS** for control and security, and **no server to run**—which is the standard for modern solo/small-team product apps.

---

## 4. CI/CD: Do We Have It? Do We Need It?

### Do we have it?

**No.** There is no CI/CD in the repo yet (no `.github/workflows` or other automation). Deploys are manual: you run the Supabase migration in the dashboard and build/run Flutter locally or via your own process.

### Do we need it?

**CI (continuous integration)** – **yes, it’s worth having.**

- **What it is:** On every push (or PR), a pipeline runs: e.g. `flutter analyze`, `flutter test`, and optionally `flutter build apk`/`build ios` so you know the app still compiles.
- **Why it’s standard:** Catches regressions before they reach production; keeps the main branch always buildable and testable. For a solo dev, even a small pipeline (analyze + test) is the industry-standard safety net.

**CD (continuous deployment)** – **optional for now.**

- **What it is:** Every merge to `main` (or a release tag) automatically deploys: e.g. Flutter app to Play Store / App Store / web, and/or Supabase migrations to production.
- **Why you might add it later:** When you have real users or testers, auto-deploying from `main` saves time and reduces “forgot to deploy” mistakes. For a private/solo project in early stage, doing deploys manually is fine; CD becomes more important when you ship often or work with others.

### What to implement (recommended)

- **CI (recommended now):** GitHub Actions workflow that on push/PR:
  - runs `flutter pub get` and `flutter analyze` in the `flutter/` folder,
  - runs `flutter test` in the `flutter/` folder.
- **CD (optional now):** Later you can add:
  - a job that runs `supabase db push` (or applies migrations) when you want,
  - or a job that builds the Flutter app artifact (e.g. APK) for download or store upload.

Next step in this repo: add a single workflow under `.github/workflows/` that does the CI part above. No CD until you want automated deploys.
