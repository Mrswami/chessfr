# System Architectural Specification & Context Manifest
## Next-Generation AI-Driven Chess Training & Aggregation Framework (`ChessFr`)

---

## Executive Summary

Modern digital chess training suffers from fragmented ecosystems and flawed training paradigms. Industry-leading platforms (Chess.com, Lichess, Chessable, Aimchess) each solve isolated problems—game matching, open-source server scaling, spaced-repetition opening memory, and post-game diagnostic metrics—yet fail to address the core cognitive breakdown that occurs inside the human calculation engine during real-time play.

This document serves as a comprehensive system prompt and contextual specification for the LLM-driven **ChessFr** framework. By synthesizing the best features of incumbent platforms with custom cognitive-behavioral evaluation frameworks, this system bridges the gap between raw PGN database ingestion, real-time tactical calculation, and behavioral data science.

---

## 1. Market Synthesis & Industry Best Practices

To build a superior training pipeline, the system incorporates proven mechanics from leading platforms while rectifying their key flaws:

| Platform | Inherited Feature | Systemic Limitation Fixed |
| :--- | :--- | :--- |
| **Chess.com** | Visual Game Review, move classification badges, interactive computer bot personalities. | Fixes artificial puzzle rating inflation and superficial move explanations that fail to address calculation habits. |
| **Lichess** | Open-source API architecture, broadcast indexing, public database telemetry, zero paywalls. | Aggregates fragmented event streams into a single unified broadcast feed. |
| **Chessable** | MoveTrainer® spaced-repetition technology for repertoire retention. | Replaces rigid, brute-force move memorization with structural pattern recognition (Tabiya Trees). |
| **Aimchess** | Post-game analytics, time-trouble indicators, blunder classification. | Integrates cognitive behavioral tracking (the P-CBA Loop) directly into the evaluation layer rather than merely recording errors. |

---

## 2. Cognitive Calculation Architecture: The P-CBA Universal Protocol

Standard tactical puzzles distort a player's calculation engine by guaranteeing that a winning move exists. This creates a **Puzzle Inflation Fallacy**, where players over-index on immediate attacks (Layer A) while completely skipping defensive geometry and boundary scans.

To correct this "Red Mist" (tactical tunnel vision), the system enforces a strict four-layer linear verification query before any move execution:

```
[ Board State ] ---> (P) Permanent Mutations ---> (C) Constraint Analysis ---> (B) Boundary Scan ---> (A) Actuation
```

### The Four Execution Layers

1. **P — Permanent Mutations (Pawns & Structural Timelines)**:
   - **Focus**: Advanced pawns, irreversible pawn pushes, and temporal deadlines (e.g., 6th/7th rank passed pawns).
   - **Rule**: Pawns cannot move backward. Every pawn push permanently alters the structural control of key squares.

2. **C — Constraint Analysis (Checks & Forced Lines)**:
   - **Focus**: Forcing moves that narrow the opponent's response matrix (checks, forced recaptures, perpetual windmill loops).
   - **Rule**: Assume forced draws or forced simplifications are high-priority operational outcomes when under strategic pressure.

3. **B — Boundary & Beam Scan (X-Rays, Snipers & Backward Mobility)**:
   - **Focus**: Long-range diagonals, stationary defenders, absolute pins, and backward piece flight squares.
   - **Rule**: Scan the entire board for static tethers before executing forward attacks.

4. **A — Actuation / Avalanche (Attacks, Liquidations & Mating Nets)**:
   - **Focus**: Executing piece trades, tactical forks, and king-safety sacrifices.
   - **Rule**: Layer A is strictly gated by Layers P, C, and B. Firepower is only authorized after structural validation.

---

## 3. Repertoire Engineering & Personal Tabiya Trees

### The Anti-Cavern Philosophy
The system actively rejects slow, bureaucratic, positional grinds (termed "The Cavern" or rigid Carlsbad structures) in favor of high-entropy, open-highway setups. It prioritizes dynamic space, early central clarity, and fluid piece activity.

### The C.O.R.E. Opening Screening Methodology
Every opening line added to a user's verified repertoire must pass four screening filters:

$$\text{C.O.R.E.} = \text{Center Dynamics} + \text{Operational Space} + \text{Red-Mist Triggers} + \text{Endgame Transition}$$

- **Center Dynamics**: Ensures central pawns remain fluid or cleanly liquidated (e.g., Open Sicilian, Scotch Classical, Queen's Gambit Accepted).
- **Operational Space**: Guarantees minor pieces maintain active forward and backward mobility corridors.
- **Red-Mist Triggers**: Contains forcing, tactical counter-punches that induce calculation fatigue in opponents.
- **Endgame Transition**: Guarantees a structurally sound pawn skeleton if pieces are traded off early.

### Personalized Tabiya & "What-If" Analysis Trees
A Tabiya represents a quintessential middlegame pawn skeleton where opening development transitions into concrete strategic plans. The system allows users to capture "What-If" critical lines—idealized board setups based on opponent mistakes—and generates hyper-personalized puzzle streams focused on converting those exact pawn skeletons.

---

## 4. Hybrid Multi-Model System Architecture

To handle transactional game logs alongside messy behavioral data and high-entropy bot experiments, the application uses a bifurcated database model.

```
                     ┌─────────────────────────────────────────┐
                     │          Application API Layer          │
                     └────────────────────┬────────────────────┘
                                          │
                  ┌───────────────────────┴───────────────────────┐
                  ▼                                               ▼
   ┌─────────────────────────────┐                 ┌─────────────────────────────┐
   │    Relational DB (SQL)      │                 │    Document Store (NoSQL)    │
   ├─────────────────────────────┤                 ├─────────────────────────────┤
   │ - Static PGN Metadata       │                 │ - Behavioral Profiles       │
   │ - Official Elo Ratings      │                 │ - Cognitive Drift Logs      │
   │ - Tournament Results        │                 │ - Personal Tabiya Trees     │
   │ - Opening Repertoire Index  │                 │ - Alien Labs (Bot Sandbox)  │
   └─────────────────────────────┘                 └─────────────────────────────┘
```

### Database Layer Roles
- **Relational Layer (SQL)**: Guarantees schema enforcement for immutable records: official match results, ratings, moves, verified opening taxonomy, and user authentication.
- **Non-Relational Layer (NoSQL Document Store)**: Captures unstructured behavioral data, psychological blindspots, P-CBA layer execution percentages, and experimental engine matches.

### The "Alien Labs" Speculative Cache
High-entropy games against computer personalities (e.g., 1875+ rated engine bots) are isolated inside a dedicated Alien Labs collection. This prevents unconventional, non-human computer moves from polluting the user's core competitive human repertoire while preserving the tactical data for isolation diagnostics.

---

## 5. ChessPulse: Unified Global Aggregation Pipeline

To solve the fragmentation of tournament schedules across disparate platforms, the system implements an automated ingest and normalization pipeline.

```
┌───────────────────────────────────────────────────────────────────────────┐
│                           External Ingestion                              │
├──────────────┬──────────────────┬───────────────────┬─────────────────────┤
│ Chess.com    │ Lichess API      │ FIDE Ratings      │ YouTube/Twitch      │
│ PubAPI       │ (/broadcast)     │ Portal Scraper    │ API Feeds           │
└──────┬───────┴────────┬─────────┴─────────┬─────────┴──────────┬──────────┘
       │                │                   │                    │
       └────────────────┴─────────┬─────────┴────────────────────┘
                                  ▼
                     ┌──────────────────────────┐
                     │   Normalization Engine   │
                     ├──────────────────────────┤
                     │ - Schema Unification     │
                     │ - Fuzzy Deduplication    │
                     │ - GM Density Ranking     │
                     └────────────┬─────────────┘
                                  ▼
                     ┌──────────────────────────┐
                     │   Redis Cache Layer      │
                     │   (TTL: 3600 Seconds)    │
                     └────────────┬─────────────┘
                                  ▼
                     ┌──────────────────────────┐
                     │ Unified Live News Feed   │
                     └────────────┬─────────────┘
```

### Core Aggregator Features
- **Multi-Source Ingestion**: Automated collectors for Chess.com PubAPI, Lichess Broadcasts, FIDE rated events, USCF/ECF tournament portals, and media drops (C-Squared, Hikaru Nakamura, etc.).
- **Fuzzy Deduplication Engine**: Merges duplicate tournament entries across sources using title similarity matching within 24-hour date windows.
- **The "Hype" Meter**: Ranks live event popularity by combining Grandmaster (GM) density scores with real-time Twitch/YouTube viewer counts.
- **One-Click Calendar Sync**: Exportable iCal/Google Calendar feeds for major global OTB and online seasons.

---

## 6. System Implementation & Diagnostic Schema

### Behavioral Flaw Log Schema (JSON)

```json
{
  "user_id": "usr_jacob_01",
  "timestamp": "2026-08-08T22:38:12Z",
  "cognitive_profile": {
    "game_elo": 950,
    "puzzle_elo": 1450,
    "cognitive_drift_variance": 0.34
  },
  "behavioral_flaws": [
    {
      "flaw_id": "err_red_mist_09",
      "category": "Vector-Processing Bottleneck",
      "trigger": "Premature piece capture without scanning back-rank tethers",
      "p_cba_failure_layer": "B (Boundary / Beam Scan)",
      "heuristic_fix": "Verify stationary defenders and baseline flight corridors before executing Layer A captures."
    }
  ],
  "active_tabiya_nodes": [
    {
      "tabiya_id": "tab_scotch_classical",
      "eco": "C45",
      "key_structure": "Open Center / Active Dark-Square Diagonal",
      "status": "Verified Repertoire"
    }
  ]
}
```

---

## Summary of System Guidelines for LLM Execution

When serving as the intelligence engine for this application, the LLM must:

1. **Enforce the P-CBA Loop**: Structure tactical analysis sequentially—Pawns/Permanence first ($P$), Checks second ($C$), Boundary/Beams third ($B$), Attacks last ($A$).
2. **Maintain Repertoire Integrity**: Screen openings using C.O.R.E. metrics, filtering out passive setups in favor of open highways and dynamic piece coordination.
3. **Isolate Behavioral Context**: Distinguish between classical human play and high-entropy bot experiments (**Alien Labs**).
4. **Provide Architectural Diagnostics**: Translate engine evaluations into structural, cognitive, and procedural feedback rather than raw numerical notation.
