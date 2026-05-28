# Implementation Plan: ChessTrainerXl Machine Learning Prediction Warehouse

This plan outlines the finalized, approved architecture and task roadmap for our **Machine Learning Prediction Warehouse** (`backend/ml_service/`). By blending raw board representation with "Universe B" connectivity analytics, we will create a highly customizable deep learning system that maps human-centric playstyles and cognitive blunders.

---

## 🎯 Finalized Design Decisions (Approved)

During our interactive workshop, we aligned on the following core design pillars:

1.  **Phase 1 Target**: Focus entirely on the **DankFish Move Predictor**, establishing a robust baseline of human-move distributions.
2.  **Elo Bracket**: Target the **Mid-Tier (1000–1400 Elo)** bracket. This range provides the most statistically rich, predictable human blunders and psychological motifs (like early Queen aggression).
3.  **Feature Engineering**: Use a **Hybrid Board Tensor** that combines:
    *   Standard $64 \times 12$ piece placement matrices.
    *   **Universe B Channel**: Active protection overlap, centralization metrics, and fragmented cluster indices generated directly by our custom `PatternEngine`.
4.  **Local & Scaleable Hosting**: Implement an **Integrated Python Service** (`backend/ml_service/`) using FastAPI and PyTorch Lightning. 
    *   *Cost*: **$0.00** to run locally (training takes only minutes on standard CPU/local GPU).
    *   *Scale*: Built using modular Python scripts, making it fully compatible with your personal **Azure** VM credits or Google Colab for larger-scale cloud training later.
5.  **Flutter UI Integration**: Present predictions to the user using a dual-visual interface:
    *   **Glowing Visual Heatmap**: Glowing overlays on the board depicting predicted human move paths.
    *   **Glassmorphic Coaching Bubble**: Text-based cognitive insights using custom themed avatars.

---

## 🏗️ Technical Architecture & Directory Layout

We will create a structured python package in `backend/ml_service/` right next to the existing `backend/crawler/`.

```
backend/
└── ml_service/
    ├── requirements.txt            # Python ML dependencies (torch, onnxruntime, fastapi, etc.)
    ├── main.py                     # FastAPI server exposing prediction routes
    ├── config.py                   # Hyperparameters, tensor dimensions, and paths
    ├── data/
    │   ├── __init__.py
    │   └── dataset_loader.py       # Loads PGN games and builds Hybrid Board Tensors
    ├── models/
    │   ├── __init__.py
    │   ├── architecture.py         # PyTorch Lightning Neural Network definitions
    │   └── registry.py             # Loads and runs inference on compiled .onnx files
    └── pipeline/
        ├── __init__.py
        ├── train_move_predictor.py # Supervised baseline training script
        └── export_onnx.py          # Compiles trained models to fast ONNX binaries
```

---

## 📋 Task Checklist

### Phase 1: Environment Setup
- `[ ]` Create `backend/ml_service/requirements.txt` with PyTorch, Lightning, FastAPI, and ONNX Runtime.
- `[ ]` Define global constants, tensor dimensions, and directory paths in `config.py`.

### Phase 2: Feature Engineering & Data Loading (`data/`)
- `[ ]` Implement `dataset_loader.py` to parse PGN files (using `python-chess`).
- `[ ]` Integrate `PatternEngine` to extract Connectivity Scores, cluster fragmentation, and defensive overlaps.
- `[ ]` Build the **Hybrid Board Tensor generator**, outputting a unified numpy/torch dataset of piece coordinates + connectivity matrices.

### Phase 3: Model Architecture & Training (`models/`, `pipeline/`)
- `[ ]` Design the PyTorch model architecture in `architecture.py` (a convolutional feedforward policy head tailored for hybrid spatial + structural inputs).
- `[ ]` Write the supervised training loop using PyTorch Lightning in `train_move_predictor.py`.
- `[ ]` Write the conversion script `export_onnx.py` to compile the checkpoint into a production-ready `.onnx` file.

### Phase 4: Serving API (`main.py`)
- `[ ]` Implement the FastAPI router in `main.py` exposing `/api/v1/predict/human-move`.
- `[ ]` Write automated tests to verify route performance and prediction validation.

---

## 🛡️ Verification Plan

### Automated Tests
- Run unit tests to verify FEN string -> Hybrid Board Tensor conversion remains deterministic.
- Assert that ONNX runtime outputs exactly match PyTorch tensor predictions ($10^{-5}$ float threshold).

### Manual Verification
- Run local crawler tests to fetch 100 sample games from Lichess, run training, export the model, and send a sample REST payload to the local FastAPI endpoint to see our "DankFish" predictions and blunder metrics output in real-time.
