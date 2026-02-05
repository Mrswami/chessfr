# Pattern-Aligned Chess Coaching

This app blends engine evaluation with personalized, pattern-aligned training.
Instead of recommending the "best engine move," it ranks moves that build
connectivity between piece groups and match the user's cognitive profile.

## Core Concepts
- **Universe A (Engine):** Raw Stockfish top-line moves.
- **Universe B (Design):** Moves that maximize connectivity between fragmented piece clusters.
- **Connectivity Score (C_s):** Overlapping influence between non-adjacent piece groups.
- **Delta-V (ΔV):** Evaluation loss accepted to gain structural clarity.
- **Response Latency (R_l):** Time before move, used to monitor impulse/authority alignment.

## Design Goal
Provide a coaching layer that feels like a "personal logic filter" rather than
a generic engine evaluator. The app teaches patterns that align with the user's
strengths and decision-making tendencies.
