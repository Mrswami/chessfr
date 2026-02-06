# Training Loop: Context and Conversation

This doc explains **what the training loop is**, **how it fits the product**, and **how we implement it** (step by step and in code).

---

## What is the “training loop”?

The **training loop** is the cycle that happens every time the user trains on one position:

1. **Show** a position (board + FEN).
2. **Compute** engine top moves and our pattern-aligned ranking.
3. **Display** ranked recommendations (and optionally hide them for “guess the move”).
4. **User makes a move** on the board.
5. **Evaluate** the move (correct / recommended / other), show feedback, and **record** the result.
6. **Update** progress (XP, streak, stats) and optionally **load the next** position.

That cycle is the core “conversation” between the app and the user: we present a puzzle, they respond, we give feedback and persist the outcome. Everything else (auth, home, profile) exists to support or personalize this loop.

---

## Why it matters for your product

- **Pattern-aligned coaching** means we don’t just say “right/wrong” from the engine; we say “that was the most connected move” or “good choice for structure” and record **what** they chose and **how** it ranked. The loop is where that logic lives.
- **Response latency** (time to move) is part of your design (e.g. “Response” / impulse). The loop is where we measure it and later can feed it into the profile or analytics.
- **Gamification** (XP, streaks, levels) depends on the loop: we only grant XP and update stats when we **record** a training step. So the loop must write to `training_sessions` and update `user_stats`.

So: **the training loop is the place where “one training step” is completed and persisted.** Getting it right is what makes the app stateful and your analytics/profile ideas possible.

---

## Steps in detail (conversation flow)

| Step | Who | What happens |
|------|-----|--------------|
| 1. Enter training | App | User taps “Start Training” from Home. Training screen opens. |
| 2. Load position | App | We pick a position (for now: fixed FEN; later: from Supabase `positions` or a “session” of N positions). Board shows the position. We store **position shown at** (timestamp) for latency. |
| 3. Analyze | App | Get engine top-N (Stockfish mock or API), run design metrics, run MoveRanker with user’s cognitive profile. We get a **ranked list** and optionally store it in `move_recommendations` for analytics. |
| 4. Show recommendations | App | UI shows the ranked moves (and feedback area empty). |
| 5. User moves | User | User plays a move on the board. |
| 6. Evaluate | App | Compare chosen move to ranked list: best move → “correct” / top-N → “recommended” / else → “incorrect”. Compute **response_latency_ms** = now - position shown at. |
| 7. Feedback | App | Show message (“Excellent!”, “Good choice.”, “Check your connectivity.”). Optionally show XP earned for this step. |
| 8. Persist | App | Insert one row into **training_sessions** (profile_id, position_id, chosen_move, response_latency_ms, outcome, xp_earned). Then update **user_stats** (total_xp += xp_earned, positions_trained += 1, last_training_date, streak logic). |
| 9. Next | App / User | Either auto-load next position or show “Next” / “Back to Home”. (Current UI: user goes back manually; we can add “Next puzzle” later.) |

Steps 1–7 are mostly already in the app (board, ranking, feedback). Steps **8** (persist) and the **latency + outcome** part of 6 are what we wire up so the loop is “complete” and data flows into Supabase.

---

## Data we need for the loop

- **profile_id** – From `profiles` where `user_id = auth.uid()`. Needed for `training_sessions` and `user_stats`.
- **position_id** – From `positions` where `fen = current_fen`; if missing, we can insert the position and use the new id (or skip persistence for unknown positions; your choice).
- **Outcome** – `correct` if chosen move is rank #1, `incorrect` if not in top-N, or we can use a middle value like `recommended` for top-3.
- **response_latency_ms** – `now - position_shown_at` when the user makes the move.
- **xp_earned** – Simple rule for now: e.g. 10 for correct, 5 for recommended, 0 for incorrect. Stored in `training_sessions` and added to `user_stats.total_xp`.
- **Streak** – If `last_training_date` is yesterday, increment `current_streak`; if it’s today, leave streak unchanged; if it’s older, set `current_streak` to 1 (or 0). Update `longest_streak` if needed.

---

## Where this lives in the codebase

- **UI:** `flutter/lib/features/training/training_screen.dart` – board, recommendations, feedback, and the call into the “record step” logic.
- **Recording:** A small **training service** (or repository) in Dart that:
  - Takes: profile_id, position_id, chosen_move, response_latency_ms, outcome, xp_earned.
  - Inserts into `training_sessions`.
  - Fetches current `user_stats` for the profile, then updates total_xp, positions_trained, last_training_date, and streak.
- **Profile / position resolution:** Either in the training screen or in the service: resolve `auth.uid()` → profile_id once when entering training (or when loading the first position), and resolve FEN → position_id when loading the position (and optionally upsert position if we want to store new FENs).

---

## What’s implemented vs what we add

| Piece | Status |
|-------|--------|
| Load position, show board | Done (fixed FEN for now). |
| Engine top-N + MoveRanker + UI list | Done (engine mocked). |
| User moves, feedback message | Done. |
| Outcome (correct / recommended / incorrect) | Logic exists in UI; we pass it to the service. |
| response_latency_ms | Not yet: we need to store `_positionShownAt` when we finish loading and compute delta when user moves. |
| Insert `training_sessions` | To add: one row per move. |
| Update `user_stats` | To add: after insert, read then update stats (or use a Supabase function/trigger later). |
| Load profile from Supabase | To add: fetch profile by user_id when entering training. |
| Resolve FEN → position_id | To add: select from `positions` by FEN; optionally insert if missing. |
| Home Streak/XP from Supabase | To add: Home screen reads `user_stats` for the current profile so the chips show real data. |

Once these are in place, the “conversation” (training loop) is fully implemented: every training step is recorded and reflected in stats, and we have a clear place to add “next position” or “session of 5” later.

---

## Implementation status (after wiring)

- **Recording:** `TrainingRepository` in `flutter/lib/features/training/training_repository.dart` inserts into `training_sessions` and updates `user_stats` (total_xp, streak, positions_trained, last_training_date).
- **Training screen:** Resolves `profile_id` and `position_id` on load, records `_positionShownAt`, and on move computes latency, outcome, XP, and calls the repository.
- **Home:** Fetches `user_stats` and shows real Streak and XP; refreshes when returning from Training.
- **Positions insert:** Run `backend/supabase/migrations/002_positions_insert_policy.sql` in the Supabase SQL Editor so the app can create positions for FENs not already in the seed data.
