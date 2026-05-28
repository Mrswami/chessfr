# 🧠 4D Psychological Chess Vector: Specification & Hypotheses

This document establishes the official design specification for our **4-Dimensional Psychological Vector Matrix** ($[S, R, P, M]$). Rather than forcing human players into static boxes, our Machine Learning Prediction Warehouse (`backend/ml_service/`) will model players dynamically, letting the data uncover their unique, hidden cognitive patterns.

---

## 📐 The 4-Dimensional Vector Model $[S, R, P, M]$

Every player is represented as a point in a continuous four-dimensional space:

```
                  [S] Structural Strategy
                     (Snake vs. Firebrand)
                             ▲
                             │
                             │
[R] Risk Tolerance ◄─────────┼─────────► [P] Pacing & Impulsivity
(Turtle vs. Gambler)         │           (Metronomic vs. Reactive)
                             │
                             ▼
                  [M] Structural Valuation
                   (Materialist vs. Idealist)
```

### 1. Structural Strategy ($S$) — *Positional vs. Tactical*
*   **0.0 (The Snake)**: Hyper-connected, defensive, and slow. They maintain low cluster fragmentation (high piece connectivity, high overlapping defense) and actively avoid early tension.
*   **1.0 (The Firebrand)**: Sharp, chaotic, and open. They crave open lines and immediate contact, and are comfortable leaving pieces in isolated, un-networked clusters if it unlocks active files or tactical motifs.

### 2. Risk Tolerance ($R$) — *Prudent vs. Gambler*
*   **0.0 (The Turtle)**: Over-defends, fears tactical complications, and prioritizes absolute safety. They will play passive, sub-optimal moves just to maintain complete security.
*   **1.0 (The Gambler)**: Thrives on uncertainty. They rely on "consuming threats" and play high-risk, speculative sacrifices to induce panic, betting that human time scrambles and visual fatigue will cause a blunder.

### 3. Pacing & Impulsivity ($P$) — *Metronomic vs. Reactive*
*   **0.0 (The Metronomic)**: Disciplined pacing. They partition their time logically according to position complexity and connectivity changes.
*   **1.0 (The Reactive / Trigger-Happy)**: Highly impulsive under threat. They jump instantly at recaptures (recapture bias) and make snap decisions in tactical situations, leaving them vulnerable to deep, multi-turn trap designs.

### 4. Valuation & Harmony ($M$) — *Materialist vs. Idealist*
*   **0.0 (The Materialist)**: Values physical chess pieces above all. They will grab exposed pawns or minor pieces even if it fractures their entire piece network and leaves their king vulnerable.
*   **1.0 (The Idealist)**: Values structural connectivity, piece flow, and overall board coordination over material. They are happy to sacrifice material to maintain a harmonious, highly active position.

---

## 🎭 1000–1400 Elo Psychological Archetypes

To reflect the real platform meta, we have defined six specialized opponent profiles mapped to the most common opening choices in the 1000–1400 bracket:

### 1. 💂 The London Squeezer (D02 / D00) — *[S: 0.1, R: 0.2, P: 0.4, M: 0.3]*
*   **Opening Behavior**: Plays d4, Bf4, e3, c3 almost automatically.
*   **Psychological Trait**: Sneaky and non-confrontational. They hate open tactical lines. If you disrupt their pyramid pawn chain early, they often suffer a **Time Variance Spike** (freeze up) or offer premature piece trades to dry up the position.

### 2. 👑 The Wayward Queen Raider (Scandinavian / Wayward Queen) — *[S: 0.8, R: 0.9, P: 0.9, M: 0.2]*
*   **Opening Behavior**: Plays 1.e4 d5 (Scandinavian) or 1.e4 e5 2.Qh5 (Wayward Queen).
*   **Psychological Trait**: High impulsivity and queen-centric obsession. They are only comfortable attacking with their Queen active. If their Queen is chased, harassed, or traded off, their tactical blunder rate spikes by over 60%, and they frequently collapse under simple pawn threats.

### 3. 🍖 The Fried Liver Fanatic (C57 / Italian Ng5) — *[S: 0.9, R: 0.8, P: 0.7, M: 0.6]*
*   **Opening Behavior**: Automatically coordinates Bc4 and Ng5, hunting for the f7 weakness.
*   **Psychological Trait**: Single-track tactical aggressor. They look for specific, memorized trap patterns and ignore overall piece connectivity. If the f7 target is securely neutralized positional-style, they quickly lose interest and blunder simple backward piece developments.

### 4. 🛡️ The French/Caro Squeezer (C00 / B10) — *[S: 0.1, R: 0.1, P: 0.3, M: 0.4]*
*   **Opening Behavior**: Responds to e4 with e6 (French) or c6 (Caro-Kann).
*   **Psychological Trait**: High safety prioritization. They over-defend pieces and pack their army into hyper-connected, compact structures. However, they struggle with spatial claustrophobia—when their space is squeezed, they panic and blunder under crowded board states.

### 5. 💣 The Gambiteer (King's Gambit / Evans / Danish) — *[S: 0.9, R: 0.9, P: 0.6, M: 0.9]*
*   **Opening Behavior**: Readily sacrifices pawns (or minor pieces) in the first 5 moves for rapid, open files.
*   **Psychological Trait**: Absolute idealist. They prioritize immediate piece activity and "consuming threats" above all material values. Highly dangerous in open, tactical lines, but completely blind to slow, grindy endgames where their missing material catches up to them.

### 6. 🦘 The Symmetrical Copier (e4 e5 Copycat) — *[S: 0.4, R: 0.3, P: 0.8, M: 0.3]*
*   **Opening Behavior**: Mimics white's developing moves exactly (Nf3 Nf6, Nc3 Nc6).
*   **Psychological Trait**: Highly reactive and insecure. They lack active plans and rely on copying or waiting for white to make a move. When the symmetry is broken with an unexpected structural threat, they display massive decision delay.

---

## 🕶️ The "AmateurSwami" Personalized Bias Tracker

Instead of just tracking opponents, our ML Prediction Warehouse will calculate your personal playing footprint. By analyzing your game database against Stockfish and the `PatternEngine`, we will determine **THE AMATEURSWAMI's** specific cognitive biases:

### 1. Development Principle Bias (Pieces over Pawns)
*   *Heuristic definition*: When presented with an equal-evaluation choice between a minor piece development move (e.g. developing a knight/bishop) and a structural pawn break/pawn push.
*   *What we track*: Your selection ratio. If you develop pieces "out of principle" when pawn structures are crying out to be pushed, we identify your **Pawn Structure Underdevelopment Index** and feed you custom pawn-chain puzzles!

### 2. Tension-Retention Index (T-R)
*   *Heuristic definition*: Measures how many plies (half-moves) you allow a tense piece-relationship (e.g., mutually attacking bishops or central pawns) to persist before you initiate a trade.
*   *What we track*: Your T-R score. Keeping tension to trade "on your terms" is an advanced master skill! If your T-R is high and leads to positive-tempo trades, our app will highlight this as a core strength.

### 3. Dynamic Piece Valuation Delta
*   *Heuristic definition*: Classical values are static (Pawn=1, Knight=3, Bishop=3, Rook=5, Queen=9). In reality, piece value is highly fluid (e.g. two minor pieces can dominate a rook in the middlegame, but crumble in a wide-open endgame).
*   *What we track*: The evaluation delta when you trade a Rook for Two Minor Pieces. If you consistently make this trade in the middlegame and win, your tactical activity rating rises. If you make it in dry endgames and lose, we point out your endgame valuation bias.

---

## 🎨 ADHD-Friendly Visual ML Dashboard & Legend

To ensure absolute visual clarity and prevent abstract confusion, the board overlays feature a **clear, interactive legend key** explaining exactly what each heat map density and color spectrum represents.

### 🗺️ The Overlay Legend Key

| Color Spectrum | Visual Representation | Density & Intensity Scale | Core Meaning |
| :--- | :--- | :--- | :--- |
| 🟢 **Emerald Green** | **Move Probability** | • *Soft glow*: Low probability (10-25%)<br>• *Dense cloud*: Expected human candidate move (50%+) | Shows the squares where the selected opponent archetype is most likely to move their pieces next. |
| 🟡 **Amber Neon** | **Blunder / Trap Risk** | • *Pulsing border*: Tactical bait setup<br>• *Bright neon circle*: High probability of human error (70%+) | Highlights blunder-prone squares where players at this Elo frequently drop material or fall for traps. |
| 🔵 **Sapphire Blue** | **Connectivity Weights** | • *Thin laser line*: Single protection connection<br>• *Dense neon beam*: Multi-piece overlap network | Visualizes the `PatternEngine` network, showing which piece-to-piece connections the model's weights are actively relying on. |
| 🔴 **Pulsing Crimson** | **Cognitive Tunnel Vision** | • *Target crosshair*: Opponent's obsessive focus square<br>• *Fading aura*: Ignored/blind squares | Shows the squares that are completely consuming the opponent's attention (usually around your Queen or a King threat), blinding them to actions elsewhere. |

> [!TIP]
> **Ad-hoc Tooltips**: Hovering over (or tapping) any colored square on the chessboard will open a glassmorphic micro-tooltip displaying the exact percentage metrics (e.g. `Human Move Probability: 84% (High Recapture Bias)` or `Blunder Risk: 73%`).

---

### 1. Real-Time Input Feature Visualization
Instead of feeding the model a flat numpy array, the dashboard will show a **Layered Grid Visualizer**:
*   **Piece Coordinate Layers**: 12 grid maps showing where the model sees Pawns, Knights, Bishops, Rooks, Queens, and Kings.
*   **The Universe B Layers**: Heatmaps generated by `PatternEngine` shown as color gradients directly on an interactive board:
    *   *Protection Overlap*: Highly protected squares glow warm orange; isolated pieces are cold blue.
    *   *Cluster Boundaries*: Colorful circles drawn around disconnected "clusters" of pieces, showing how fragmented the army is.

### 2. Model Weight & Bias Histograms
*   A clean, automatic plotting interface (using lightweight **Plotly** or **Streamlit**) that displays the distribution of weights and biases inside each layer of our DankFish model.
*   **ADHD Tip**: Instead of inspecting numbers, you'll see a bell-curve histogram. If the model is training correctly, you'll see the bell curve smoothly expand and shift. If it's dead or over-fitting, you'll immediately see the curve collapse into a single spike.

### 3. Layer-by-Layer Attention Maps (Flutter Chessboard Overlays)
As you play or analyze:
*   We can overlay the neural network's **attention weights** directly on the Flutter chessboard.
*   Squares or pieces that the model's weights prioritized during its "forward pass" will glow with a soft aura.
*   **The Value**: You will see *exactly* which piece connections and files the model's weights used to make its prediction (e.g., seeing the model's "gaze" fixate heavily on the F7 weakness or the connection between a pinned knight and an undefended queen).
