# ♟️ ChessTrainerXl: Machine Learning Warehouse Project Overview

This document serves as the absolute source of truth summarizing our conceptual progress, structural decisions, and future roadmap. **Copy and paste the contents of this file (or point the next chat to it) to instantly boot up your next session with 100% context parity.**

---

## 🚀 The Core Vision: Universe B Chess
**ChessTrainerXl (chessfr)** is a premium, next-generation chess training ecosystem. Unlike traditional tools that evaluate positions purely through dry engine-calculating computers (Stockfish), this project focuses heavily on **human-centric psychology and piece networks ("Universe B")**.

We are building a highly customized **Machine Learning Prediction Warehouse** (`backend/ml_service/`) that uses deep learning to model, predict, and visualize real human-playing habits, blunders, and opening-based psychologies.

---

## 📐 The 4D Psychological Vector Matrix $[S, R, P, M]$
Players are modeled as continuous coordinates in a four-dimensional psychological space:
1.  **Structural Strategy ($S$) — *Snake (0.0) vs. Firebrand (1.0)***: Cautious, hyper-connected closed-center play vs. open-file, fragmented tactical contact.
2.  **Risk Tolerance ($R$) — *Turtle (0.0) vs. Gambler (1.0)***: Over-defensive safety vs. high-pressure speculative sacrifices.
3.  **Pacing & Impulsivity ($P$) — *Metronomic (0.0) vs. Reactive (1.0)***: Smooth time management vs. snap-recaptures and time-pressure panic.
4.  **Valuation & Harmony ($M$) — *Materialist (0.0) vs. Idealist (1.0)***: Grabbing raw points vs. sacrificing material for coordinate piece harmony.

---

## 🎭 1000–1400 Elo Psychological Archetypes
We have developed 6 distinct opponent profiles representing the actual platform meta in our targeted Elo range:
*   **The London Squeezer**: Cautious, avoids tactical center breaks, freezes (Time Variance Spike) when their pawn pyramid is broken.
*   **The Wayward Queen Raider**: Early Queen aggressor, highly impulsive, collapses when the Queen is chased or traded.
*   **The Fried Liver Fanatic**: Hyper-focused on the f7 square, loses tactical coordination if f7 is neutralized positional-style.
*   **The French/Caro Squeezer**: Over-defensive, packs piece networks tightly, panics under cramped spatial confinement.
*   **The Gambiteer**: Material-sacrificing idealist, creates "consuming threats" to induce tunnel-vision blunders; weak in slow endgames.
*   **The Symmetrical Copier**: Copycat developer, passive and reactive, suffers massive decision delay when symmetry is broken.

---

## 🕶️ The "AmateurSwami" Personalized Bias Tracker
Instead of just static training, the system fine-tunes baseline models specifically to **THE AMATEURSWAMI's** (the user's) unique playing footprint:
*   **Development Principle Bias**: Identifying if you develop minor pieces out of principal when a dynamic pawn break or pawnstorm was mathematically stronger.
*   **Tension-Retention Index (T-R)**: Tracking your ability to maintain complex board tension and trade strictly on your own terms to gain tempo.
*   **Dynamic Piece Valuation Delta**: Evaluating how you transition piece values throughout different phases (e.g., trading a Rook for two minors in the active middlegame vs. a dry endgame).

---

## 🎨 ADHD-Friendly Model Visualizer & Color Legend
To prevent getting lost in weights and tensor matrices, we designed an interactive board overlay system accompanied by a clear, dedicated key and hover tooltips:

*   🟢 **Emerald Green (Move Probability)**: Shows where the selected archetype is most likely to move. Density represents likelihood.
*   🟡 **Amber Neon (Blunder / Trap Risk)**: Highlights high-risk squares where this Elo bracket frequently drops material or misses traps.
*   🔵 **Sapphire Blue (Connectivity Weights)**: Draws laser beams showing the piece-protection paths active in the model's weights.
*   🔴 **Pulsing Crimson (Cognitive Tunnel Vision)**: Spotlights squares that are consuming the opponent's attention, causing blindness elsewhere.

---

## 📋 Approved Task Roadmap for Your Next Chat

When you start your new chat, paste or reference this outline to begin execution immediately:

### 1. File Structure Setup
Create the ML package under `backend/ml_service/` featuring:
*   `requirements.txt` (PyTorch, Lightning, ONNX Runtime, FastAPI, python-chess)
*   `main.py` (FastAPI router)
*   `config.py` (Tensor dimensions and paths)

### 2. Feature Engineering (`data/dataset_loader.py`)
*   Implement PGN extraction using `python-chess`.
*   Integrate `PatternEngine` to construct our **Hybrid Board Tensors** (64x12 coordinates + connectivity, overlapping protection, and cluster fragmentation channels).

### 3. PyTorch Model Training & ONNX Compilation
*   Build the supervised policy network in `models/architecture.py`.
*   Write the training loop using PyTorch Lightning in `pipeline/train_move_predictor.py` (designed to run locally for free, or easily deployable to Azure using student/intern credits).
*   Export the trained model to `.onnx` for microsecond runtime inference.

---

## 📂 Project Conversation Topics Directory

To maintain focus and avoid cognitive overload, you can tackle the implementation across **5 distinct, chronological conversation topics**. Use these titles and objectives for your upcoming chats:

### Topic 1: 🏗️ ML Service Blueprint & Environment Configuration
*   **Objective**: Lay the foundation of the prediction warehouse. Setup the file directory `backend/ml_service/`, install environmental dependencies (`requirements.txt`), and establish global tensor dimensions and directories inside `config.py`.
*   **Goal**: Ensure our environment builds and compiles with zero conflicts.

### Topic 2: 📊 Hybrid Tensor Feature Engineering & Data Pipeline
*   **Objective**: Program the parser that feeds our model. Build `data/dataset_loader.py` to ingest PGN game records and use our custom `PatternEngine` to construct our **Hybrid Board Tensors** (merging 12 piece coordinate channels with connectivity, overlap protection, and cluster fragmentation channels).
*   **Goal**: Convert a raw FEN or PGN string into clean, multi-layered visual numpy tensors.

### Topic 3: 🧠 DankFish Neural Network Architecture & Supervised Training
*   **Objective**: Design and train our brain. Code the convolutional feedforward neural network in `models/architecture.py` and write the training routine in `pipeline/train_move_predictor.py` using **PyTorch Lightning**. Train the baseline on crawled Lichess 1000-1400 PGNs.
*   **Goal**: Save a fully trained PyTorch checkpoint with decreasing loss curves.

### Topic 4: 🛠️ Model Compiler, Registry, & FastAPI Prediction Endpoints
*   **Objective**: Compile weights and expose them via API. Create `export_onnx.py` to compile our neural network weights into high-speed `.onnx` binaries. Build `models/registry.py` to manage model sessions, and implement FastAPI endpoints (`/api/v1/predict/human-move`) inside `main.py`.
*   **Goal**: Send a FEN payload via a REST client and receive millisecond predictions.

### Topic 5: 🕶️ The AmateurSwami Bias Tracker & Visual Dashboard
*   **Objective**: Personalize the logic and build the inspectable visuals. Write the calculation code for your personalized biases (T-R index, Development Bias, Piece Valuation transitions) and create a lightweight, visual inspector dashboard (using Streamlit or Plotly) showing layer-by-layer attention overlays, weight bell-curves, and input grids.
*   **Goal**: Easily inspect what the model sees and tracks to keep your head perfectly on the data!
