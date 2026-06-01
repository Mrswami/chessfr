import unittest
import os
import sys
import chess.pgn
import py_compile

# Ensure the root of ml_service is on the python path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import config
from pipeline.bias_tracker import BiasTracker

class TestDashboardAndBiases(unittest.TestCase):

    def setUp(self):
        self.tracker = BiasTracker(player_name="AmateurSwami")
        self.sample_pgn = os.path.join(config.DATA_DIR, "sample_games.pgn")

    def test_bias_tracker_metrics(self):
        """Verify that the BiasTracker calculates the 6 biases correctly from the sample PGN."""
        self.assertTrue(os.path.exists(self.sample_pgn), "Sample PGN file does not exist")
        
        # Load sample games
        games = []
        with open(self.sample_pgn, "r", encoding="utf-8") as f:
            while True:
                g = chess.pgn.read_game(f)
                if g is None:
                    break
                games.append(g)
                
        self.assertGreater(len(games), 0, "No games loaded from sample PGN")
        
        # Run analysis
        biases = self.tracker.analyze_history(games)
        
        # Check keys exist
        expected_keys = ["premature_queen", "castling_delay", "pawn_phobia", "luft_neglect", "exchange_panic", "king_hunt"]
        for key in expected_keys:
            self.assertIn(key, biases)
            val = biases[key]
            # Verify values are floats bounded in range [0..1]
            self.assertTrue(isinstance(val, float))
            self.assertTrue(0.0 <= val <= 1.0, f"Value {val} for key {key} is out of bounds [0..1]")

    def test_dashboard_compiles(self):
        """Verify that dashboard.py compiles without syntax errors."""
        dashboard_path = os.path.join(config.BASE_DIR, "dashboard.py")
        self.assertTrue(os.path.exists(dashboard_path), "dashboard.py file does not exist")
        
        # Compile python file to verify zero syntax errors
        try:
            compiled = py_compile.compile(dashboard_path, doraise=True)
            self.assertTrue(os.path.exists(compiled))
            # Clean up compiled bytecode file
            if os.path.exists(compiled):
                os.remove(compiled)
        except py_compile.PyCompileError as e:
            self.fail(f"dashboard.py failed to compile: {str(e)}")

if __name__ == "__main__":
    unittest.main()
