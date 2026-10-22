# ChessFr Move Rating & Evaluation Calibration System

This document establishes the permanent calibration specification and regression benchmarks for move classification in ChessFr to prevent misclassifications (such as generic moves being labeled as "Best" or missed tactics labeled as "Great").

---

## 1. Mathematical Definitions

Centipawn loss ($CPL$) is always calculated from the perspective of the player making the move:

$$CPL = \text{eval}(\text{BestEngineMove}) - \text{eval}(\text{PlayerMove})$$

Where positive $CPL$ indicates loss of positional advantage.

| Annotation | Symbol | Color | CPL Range / Criteria | Rationale |
| :--- | :---: | :---: | :--- | :--- |
| **Brilliant** | `!!` | Cyan (`#06b6d4`) | $CPL \le 12$, $Eval \ge +150\text{cp}$, `isSacrifice = true` | Truly rare piece sacrifice that preserves decisive winning advantage. |
| **Great Move** | `!?` | Green (`#22c55e`) | $CPL \le 15$, `isOnlyGoodMove = true`, $Eval \ge -50\text{cp}$ | Found the sole saving or winning continuation when alternatives lost $\ge 150\text{cp}$. |
| **Best Move** | `!` | Emerald (`#10b981`) | $CPL \le 15$ | Matches or equals the top engine recommendation within margin of error. |
| **Good Move** | (none) | Lime (`#84cc16`) | $15 < CPL \le 60$ | Solid, natural move with negligible loss. |
| **Inaccuracy** | `?!` | Yellow (`#facc15`) | $60 < CPL \le 140$ | Minor slip that weakens initiative or concedes equalizing counterplay. |
| **Mistake** | `?` | Orange (`#fb923c`) | $140 < CPL \le 275$ | Significant error that turns a win into a draw or equality into disadvantage. |
| **Blunder** | `??` | Red (`#ef4444`) | $CPL > 275$ | Decisive tactical blunder, hanging major piece, or allowing mate. |

---

## 2. Piece Sacrifice Verification Heuristics

A move qualifies for `isSacrifice` **only** if:
1. The moving piece is non-pawn ($Q, R, B, N$).
2. The destination square is attacked by opponent pawns or pieces with equal/lower value.
3. The move was **not** an exchange of equal/higher value (i.e. did not capture an opponent piece of equal or greater value).
4. Castling (`O-O`, `O-O-O`) is explicitly excluded.

---

## 3. Calibration Regression Test Cases

### Test Case 1: Hanging Queen (Blunder)
- **Position**: `r1bqkb1r/pppp1ppp/2n5/4p3/2B1n3/5Q2/PPPP1PPP/RNB1K1NR w KQkq - 0 5`
- **Player Move**: `Qe2` (missing checkmate and losing queen)
- **Expected Rating**: `blunder` (`??`)
- **Expected CPL**: $> 300\text{cp}$

### Test Case 2: Natural Developing Move (Good Move, NOT Best)
- **Position**: `rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1`
- **Player Move**: `d6` (solid Pirc defense, second-tier choice after e5/c5)
- **Expected Rating**: `good`
- **Expected CPL**: $20 - 45\text{cp}$

### Test Case 3: Top Engine Choice (Best Move)
- **Position**: `rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1`
- **Player Move**: `c5` or `e5` (top tier)
- **Expected Rating**: `best` (`!`)
- **Expected CPL**: $0 - 10\text{cp}$

### Test Case 4: Missed Tactic (Mistake / Blunder, NEVER Great)
- **Position**: Player had $+3.2$ tactical pin, but played passive move reducing eval to $+0.8$.
- **CPL**: $+240\text{cp}$
- **Expected Rating**: `mistake` (`?`)
