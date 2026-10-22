# Rule: Chess Move Classification & Anti-Inflation Invariants

1. **Brilliant Move (`!!`) Invariant**:
   - A move MUST NOT be classified as Brilliant unless all four conditions are met:
     1. **True Piece Sacrifice**: The piece moved ($Q, R, B, N$) is placed en prise on an enemy-attacked square (`isAttacked(...)`) without capturing equal/greater material.
     2. **Decisive Continuation**: The move maintains or produces a winning evaluation ($eval \ge +1.50$ for White or $\le -1.50$ for Black).
     3. **Minimal Centipawn Loss**: The move must match the top engine continuation ($cpLoss \le 10$).
     4. **Routine Move Prohibition**: Common developing or positioning moves (e.g. `Re1`, `O-O`, `Nf3`) must NEVER receive a Brilliant rating.

2. **Great Move (`!?`) Invariant**:
   - Must be awarded sparingly (at most 1–2 per game).
   - Only assigned when a player discovers an elusive save or executes a major swing ($cpLoss \le -120$ centipawns into a solid position), not for ordinary top engine moves.

3. **Standard Move Baseline**:
   - Ordinary top engine choices are **Best (`!`)**.
   - Standard solid moves ($cpLoss \le 80$) are **Good Moves** (neutral glyph).

4. **UI Scrolling Isolation**:
   - When scrolling move lists or navigation tapes, NEVER use unbounded window scrolling (e.g., global `scrollIntoView()`).
   - Use direct horizontal/vertical offset math on the scroll container:
     `container.scrollTo({ left: targetScrollLeft, behavior: 'smooth' })`
     to guarantee the board and parent viewport remain completely motionless.
