---
name: chess-analysis-calibration
description: Best practices for implementing chess move classification, centipawn loss calculation, sacrifice verification, and motionless UI auto-scrolling.
---

# Chess Analysis Calibration Workflow

## Evaluation Delta & Perspective
Always compute centipawn loss from the moving player's point of view:
```ts
const cpLoss = turn === 'w' ? (evalBefore - evalAfter) : (evalAfter - evalBefore);
const evalForPlayer = turn === 'w' ? evalAfter : -evalAfter;
```

## Threshold Guidelines
| Annotation | Symbol | Criteria |
|---|---|---|
| Brilliant | `!!` | Genuine piece sacrifice + $evalForPlayer \ge 150$ + $cpLoss \le 10$ |
| Great Move | `!?` | Major swing ($cpLoss \le -120$) into solid position |
| Best Move | `!` | Top engine choice ($cpLoss \le 12$) |
| Good Move | (none) | Sound move ($cpLoss \le 80$) |
| Inaccuracy | `?!` | Minor slip ($80 < cpLoss \le 160$) |
| Mistake | `?` | Significant error ($160 < cpLoss \le 300$) |
| Blunder | `??` | Game-altering blunder ($cpLoss > 300$) |

## Piece Sacrifice Verification Check
```ts
const enemyColor = move.color === 'w' ? 'b' : 'w';
const isTargetAttacked = chess.isAttacked(move.to as Square, enemyColor);
const isPiece = ['q', 'r', 'b', 'n'].includes(move.piece);
const isSac = isPiece && isTargetAttacked && !move.captured && !move.san.includes('O-O');
```

## Viewport Preservation Pattern
When scrolling items inside sub-containers or tapes, avoid `scrollIntoView()` which forces parent/window scroll jumps. Instead, compute container-relative coordinates:
```ts
const containerRect = container.getBoundingClientRect();
const chipRect = activeChip.getBoundingClientRect();
const offsetLeft = chipRect.left - containerRect.left;
const targetScrollLeft = container.scrollLeft + offsetLeft - (containerRect.width / 2) + (chipRect.width / 2);
container.scrollTo({ left: targetScrollLeft, behavior: 'smooth' });
```
