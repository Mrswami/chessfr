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

---

## Translation Key (for Cursor / technical handoff)

When implementing or auditing, map "Pattern-Aligned" product language to these concrete behaviors:

| Term | Technical meaning |
|------|-------------------|
| **Connectivity** | Reward moves that reduce the distance between isolated piece clusters (Quad-Split support). |
| **Response** | Penalty for moves with latency < 2.0s (Impulse control for MG/Emotional Authority). |
| **Influence** | Reward moves where pieces are "Networked" (4-line logic). |

---

## 🛠️ Professional Standards (2026 Roadmap)

*   **CI/CD:** Automated linting and builds via GitLab/GitHub Actions to maintain logic integrity.
*   **Modern Packaging:** Using `pyproject.toml` and `venv` for reproducible, isolated Python builds.
*   **Ethical Crawling:** 
    -   Always check `robots.txt` before fetching data.
    -   Identify the bot with a clear `User-Agent`.
    -   Implement 'Polity' delays (randomized 1-3s) to respect platform resources.
*   **Security:** Multi-layer secret management (.env and CI secrets).
*   **Collaborative Ingestion:** The user selects games to "import" to avoid "flukes" and ensure high-quality training data.
