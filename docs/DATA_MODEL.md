# Data Model (Draft)

This is a minimal, SQL-friendly model for Supabase/Postgres.

## Tables

### profiles
Stores the user's coaching profile (pattern alignment inputs).
- id (uuid, pk)
- user_id (uuid, fk -> auth.users)
- display_name (text)
- cognitive_profile (jsonb) -- e.g., "Connectivity/Response/Influence" weights
- created_at (timestamptz)

### positions
Stores a FEN and optional metadata.
- id (uuid, pk)
- fen (text, unique)
- side_to_move (text)
- tags (text[])
- created_at (timestamptz)

### move_recommendations
Engine + design candidates for a position and profile.
- id (uuid, pk)
- position_id (uuid, fk -> positions)
- profile_id (uuid, fk -> profiles)
- engine_top3 (jsonb) -- array of { move, eval }
- design_metrics (jsonb) -- is_bridge, island_count, connectivity_gain
- delta_v (numeric)
- recommendation_logic (text)
- ranked_moves (jsonb) -- final ordered list
- created_at (timestamptz)

### training_sessions
Captures user response and progress.
- id (uuid, pk)
- profile_id (uuid, fk -> profiles)
- position_id (uuid, fk -> positions)
- chosen_move (text)
- response_latency_ms (int)
- outcome (text) -- e.g., "accepted", "rejected", "delayed"
- created_at (timestamptz)

## Notes
- Use JSONB for evolving heuristic metrics.
- Keep the schema small until patterns stabilize.
