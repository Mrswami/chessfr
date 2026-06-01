import unittest
import chess
import numpy as np
import os
import sys

# Ensure backend/ml_service is on the python path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from data.dataset_loader import DatasetLoader, PGNDataset
from data.pattern_engine import PatternEngine
import config

class TestDataPipeline(unittest.TestCase):

    def setUp(self):
        self.loader = DatasetLoader()
        self.engine = PatternEngine()

    def test_tensor_shape(self):
        """Verify that the generated Hybrid Board Tensor has the correct shape (20, 8, 8)."""
        start_fen = chess.STARTING_FEN
        tensor = self.loader.fen_to_hybrid_tensor(start_fen)
        
        self.assertEqual(tensor.shape, (20, 8, 8))
        self.assertEqual(tensor.dtype, np.float32)

    def test_move_encoding_roundtrip(self):
        """Verify that encoding and decoding a move is perfectly symmetric."""
        board = chess.Board()
        for move in board.legal_moves:
            idx = DatasetLoader.encode_move(move)
            self.assertTrue(0 <= idx < 4096, f"Index {idx} out of range for move {move}")
            
            decoded = DatasetLoader.decode_move(idx, board)
            self.assertEqual(move, decoded, f"Round-trip failed: original {move} != decoded {decoded}")

    def test_starting_position_features(self):
        """Verify feature matrices for starting position are correct and normalized."""
        start_fen = chess.STARTING_FEN
        tensor = self.loader.fen_to_hybrid_tensor(start_fen)
        
        # In starting position, White has 16 pieces, and they should be clustered together.
        # Let's assert white cluster matrix has values representing a large cluster.
        # Channel 16 is white clusters
        white_clusters = tensor[16]
        # Starting pieces are on rows 6 and 7 (ranks 1 and 2)
        # Sum of pieces in white starting cluster = 16. Normalized: 16/16 = 1.0
        self.assertAlmostEqual(white_clusters[7, 0], 1.0)
        self.assertAlmostEqual(white_clusters[6, 4], 1.0)
        # Empty square has 0.0
        self.assertEqual(white_clusters[4, 4], 0.0)

        # White influence channel (Channel 14). Row 5 (Rank 3) should have active influence.
        # E.g. d4 and e4 are attacked by friendly pieces in starting position.
        white_influence = tensor[14]
        # e3 (row 5, col 4) is attacked by pawn f2, pawn d2, knight g1, etc.
        self.assertGreater(white_influence[5, 4], 0.0)

    def test_fragmented_position_features(self):
        """Verify that isolated pieces receive appropriate penalties (smaller clusters)."""
        # White has King on e1, Rook on a1, Rook on h1, Pawn on b3.
        # Pawn on b3 is completely isolated.
        fragmented_fen = "4k3/8/8/8/8/1P6/8/R3K2R w KQ - 0 1"
        tensor = self.loader.fen_to_hybrid_tensor(fragmented_fen)
        
        white_clusters = tensor[16]
        
        # Pawn on b3 (row 5, col 1) is isolated, so cluster size should be 1. Normalized: 1/16 = 0.0625
        self.assertAlmostEqual(white_clusters[5, 1], 0.0625)

    def test_pgn_dataset_missing_file(self):
        """Verify that PGNDataset handles a missing file gracefully."""
        dataset = PGNDataset(pgn_path="nonexistent_file.pgn")
        self.assertEqual(len(dataset), 0)

if __name__ == "__main__":
    unittest.main()
