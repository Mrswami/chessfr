import unittest
import os
import sys
import chess
import numpy as np

# Ensure the root of ml_service is on the python path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import config
from data.dataset_loader import DatasetLoader
from models.registry import ModelRegistry
from pipeline import export_onnx
from main import app, startup_event, predict_human_move, PredictRequest

class TestInferencePipeline(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        """Compiles the model to ONNX once before running the tests."""
        print("Compiling model for testing...")
        export_onnx.main()
        # Trigger app startup event to load registry
        startup_event()

    def test_onnx_compilation_exists(self):
        """Verify that the compiled ONNX model exists in the registry folder."""
        onnx_path = os.path.join(config.MODEL_DIR, "dankfish_baseline.onnx")
        self.assertTrue(os.path.exists(onnx_path), "ONNX model binary was not compiled successfully")

    def test_registry_prediction_shapes(self):
        """Verify that the ModelRegistry loads and returns correct shapes from the ONNX session."""
        registry = ModelRegistry()
        loader = DatasetLoader()
        
        board = chess.Board()
        tensor = loader.fen_to_hybrid_tensor(board)
        
        policy_logits, attn_probs = registry.predict(tensor)
        
        self.assertEqual(policy_logits.shape, (4096,))
        self.assertEqual(attn_probs.shape, (64,))
        self.assertTrue(np.all(attn_probs >= 0.0) and np.all(attn_probs <= 1.0), "Attention values must be sigmoid probabilities [0..1]")

    def test_live_predict_endpoint_success(self):
        """Verify that the FastAPI predict endpoint returns live inference results from the ONNX model."""
        request_payload = PredictRequest(
            fen=chess.STARTING_FEN,
            elo=1200,
            archetype="London Squeezer"
        )
        
        # Directly call the route handler function
        response = predict_human_move(request_payload)
        
        self.assertEqual(response.fen, chess.STARTING_FEN)
        self.assertGreater(len(response.top_moves), 0)
        
        # Verify the structure of the returned moves
        top_move = response.top_moves[0]
        self.assertTrue(hasattr(top_move, 'uci'))
        self.assertTrue(hasattr(top_move, 'probability'))
        self.assertTrue(hasattr(top_move, 'visuals'))
        
        # The probabilities must be between 0.0 and 1.0, and sum to <= 1.0 (since we only return top 5)
        for move in response.top_moves:
            self.assertTrue(0.0 <= move.probability <= 1.0)
            
        total_prob = sum(move.probability for move in response.top_moves)
        self.assertTrue(0.0 < total_prob <= 1.0)
        
        # Verify ADHD visual color is returned
        self.assertEqual(top_move.visuals.probability_color, "emerald")

if __name__ == "__main__":
    unittest.main()
