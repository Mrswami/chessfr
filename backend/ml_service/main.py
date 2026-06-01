import os
import uvicorn
from fastapi import FastAPI, HTTPException, status
from pydantic import BaseModel, Field
import chess
import numpy as np
from typing import List, Dict, Any, Optional

import sys
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

import config
from data.dataset_loader import DatasetLoader
from models.registry import ModelRegistry
from data.pattern_engine import PatternEngine

app = FastAPI(
    title="ChessTrainerXl Prediction Warehouse",
    description="Live Machine Learning Prediction Warehouse serving human-centric chess move probabilities and cognitive overlays via ONNX Runtime.",
    version="1.0.0",
)

# Global instances loaded at startup
registry = None
loader = None
pattern_engine = None

@app.on_event("startup")
def startup_event():
    """Initializes the model registry, data loaders, and triggers stub ONNX compilation if missing."""
    global registry, loader, pattern_engine
    loader = DatasetLoader()
    pattern_engine = PatternEngine()
    
    onnx_path = os.path.join(config.MODEL_DIR, "dankfish_baseline.onnx")
    if not os.path.exists(onnx_path):
        print("ONNX model binary not found at startup. Triggering automatic compilation pipeline...")
        # Run export_onnx script inline
        from pipeline import export_onnx
        export_onnx.main()
        
    registry = ModelRegistry()

# Request schemas
class PredictRequest(BaseModel):
    fen: str = Field(
        default="rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
        description="FEN string representing the current board state"
    )
    elo: int = Field(
        default=1200,
        ge=1000,
        le=1400,
        description="Target Elo bracket rating (1000-1400)"
    )
    archetype: str = Field(
        default="London Squeezer",
        description="Opponent playstyle archetype (e.g., London Squeezer, Wayward Queen Raider, Gambiteer)"
    )

class MoveVisualOverlay(BaseModel):
    probability_color: str = Field(..., description="Color name from our visual theme (emerald, amber, sapphire, crimson)")
    blunder_risk: float = Field(..., description="Score 0.0-1.0 representing mistake probability")
    cognitive_tunnel: bool = Field(..., description="Whether this square is part of a tunnel vision event")

class MovePrediction(BaseModel):
    uci: str = Field(..., description="Universal Chess Interface format (e.g., e2e4)")
    san: str = Field(..., description="Standard Algebraic Notation format (e.g., e4)")
    probability: float = Field(..., description="Predicted probability score (0.0-1.0)")
    insights: str = Field(..., description="Textual feedback/coaching analysis bubble content")
    visuals: MoveVisualOverlay = Field(..., description="Board overlays and colors")

class PredictResponse(BaseModel):
    fen: str = Field(..., description="Board state analyzed")
    top_moves: List[MovePrediction] = Field(..., description="Top predicted human moves sorted by probability")

@app.get("/")
def health_check():
    return {
        "status": "healthy",
        "service": "ChessTrainerXl ML Prediction Warehouse",
        "version": "1.0.0",
        "onnx_loaded": registry is not None and registry.session is not None,
        "supported_archetypes": [
            "London Squeezer",
            "Wayward Queen Raider",
            "Fried Liver Fanatic",
            "French/Caro Squeezer",
            "Gambiteer",
            "Symmetrical Copier"
        ]
    }

@app.post("/api/v1/predict/human-move", response_model=PredictResponse, status_code=status.HTTP_200_OK)
def predict_human_move(payload: PredictRequest):
    """
    Exposes predictions of human playing moves.
    Loads FEN, generates the 20-channel Hybrid Board Tensor, runs ONNX Runtime,
    and returns move probabilities and cognitive visual overlays.
    """
    if registry is None or registry.session is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Prediction engine session is not loaded."
        )

    try:
        board = chess.Board(payload.fen)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid FEN string format: {str(e)}"
        )

    legal_moves = list(board.legal_moves)
    if not legal_moves:
        return PredictResponse(fen=payload.fen, top_moves=[])

    # 1. Transform board state into our 20-channel Hybrid Tensor
    tensor = loader.fen_to_hybrid_tensor(board)

    # 2. Run ONNX Model Inference
    policy_logits, attn_probs = registry.predict(tensor)

    # 3. Softmax calculation ONLY over legal moves to normalize probabilities
    legal_logits = []
    for move in legal_moves:
        idx = DatasetLoader.encode_move(move)
        legal_logits.append(policy_logits[idx])
        
    legal_logits = np.array(legal_logits)
    # Numerical stability shift
    shifted_logits = legal_logits - np.max(legal_logits)
    exp_logits = np.exp(shifted_logits)
    normalized_probs = exp_logits / np.sum(exp_logits)

    # 4. Generate coaching feedback templates based on playstyle archetype
    insights_pool = {
        "London Squeezer": [
            "Moves align with cautious, slow pawn developments; avoiding immediate tactical breaks.",
            "Tends to avoid central center pawn trades to preserve their pyramid structure."
        ],
        "Wayward Queen Raider": [
            "Aggressive move showing early Queen focus or checkmate-seeking behavior.",
            "Impulsive tactical alignment. Collaspes if Queen target is blockaded."
        ],
        "Fried Liver Fanatic": [
            "Heavy kingside coordination. Hyper-focused on attacking the vulnerable f7 square.",
            "Tactical build-up centered around Knight/Bishop threats near the King."
        ],
        "French/Caro Squeezer": [
            "Piece network is packed tightly; shows defensive positioning behind pawn lines.",
            "Cramped piece connectivity, highly sensitive to flanking pawn storms."
        ],
        "Gambiteer": [
            "Idealist move sacrificing positional control for active attacking paths.",
            "Tactically aggressive; looking to induce tunnel vision blunders."
        ],
        "Symmetrical Copier": [
            "Passive development mirroring White's layouts; sensitive to breaking symmetry.",
            "Reluctant to create tension; chooses passive recaptures."
        ]
    }
    
    selected_insights = insights_pool.get(
        payload.archetype, 
        ["Human move matching general 1000-1400 Elo structural layout."]
    )

    # 5. Populate Move predictions and visual overlay rules
    predictions = []
    
    # Sort legal moves by their calculated probability
    sorted_indices = np.argsort(normalized_probs)[::-1]
    
    # We only return the top 5 moves for UX clarity
    num_to_return = min(len(legal_moves), 5)
    
    for i in range(num_to_return):
        orig_idx = sorted_indices[i]
        move = legal_moves[orig_idx]
        prob = float(normalized_probs[orig_idx])
        
        uci = move.uci()
        san = board.san(move)
        
        # Calculate Blunder Risk (connectivity score delta before vs after)
        turn = board.turn
        prev_conn = pattern_engine.get_connectivity_score(board, turn)
        
        board.push(move)
        new_conn = pattern_engine.get_connectivity_score(board, turn)
        board.pop()
        
        # Positive delta = loss of piece network strength = blunder risk
        conn_loss = prev_conn - new_conn
        blunder_risk = float(np.clip(conn_loss / 3.0, 0.0, 1.0))
        
        # Extract Attention probability for the destination square
        dest_sq = move.to_square
        attn_val = float(attn_probs[dest_sq])
        
        # Determine ADHD-friendly overlay colors
        if i == 0:
            color = "emerald"      # Recommended/highest likelihood move
            tunnel = False
        elif blunder_risk > 0.5:
            if attn_val > 0.4:
                color = "crimson"  # High attention + high blunder = Cognitive Tunnel Vision
                tunnel = True
            else:
                color = "amber"    # High blunder risk trap warning
                tunnel = False
        elif attn_val > 0.5:
            color = "sapphire"     # Strong connectivity pathway
            tunnel = False
        else:
            color = "sapphire"
            tunnel = False

        predictions.append(
            MovePrediction(
                uci=uci,
                san=san,
                probability=round(prob, 3),
                insights=selected_insights[i % len(selected_insights)],
                visuals=MoveVisualOverlay(
                    probability_color=color,
                    blunder_risk=round(blunder_risk, 2),
                    cognitive_tunnel=tunnel
                )
            )
        )

    # Sort final return list by probability descending
    predictions = sorted(predictions, key=lambda x: x.probability, reverse=True)

    return PredictResponse(
        fen=payload.fen,
        top_moves=predictions
    )

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
