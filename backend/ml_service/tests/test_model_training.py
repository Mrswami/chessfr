import unittest
import torch
import os
import sys

# Ensure backend/ml_service is on the python path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from models.architecture import DankFishNet, DankFishModel
from data.dataset_loader import PGNDataset
import config
import lightning as L

class TestModelTraining(unittest.TestCase):

    def setUp(self):
        self.net = DankFishNet()
        self.model = DankFishModel()

    def test_forward_pass_shapes(self):
        """Verify the model forward pass outputs correct policy and attention shapes."""
        # Create dummy batch of 2 board states (shape: batch_size, channels, rows, cols)
        dummy_input = torch.randn(2, 20, 8, 8)
        
        policy_logits, attn_probs = self.net(dummy_input)
        
        # 4096 representing all UCI move transitions
        self.assertEqual(policy_logits.shape, (2, 4096))
        # 64 representing target attention grid cells
        self.assertEqual(attn_probs.shape, (2, 64))

    def test_loss_calculation_with_blunder_weights(self):
        """Verify that training step correctly computes loss and handles blunder-weight inputs."""
        batch_size = 4
        tensors = torch.randn(batch_size, 20, 8, 8)
        move_targets = torch.randint(0, 4096, (batch_size,))
        attention_targets = torch.rand(batch_size, 64)
        is_blunder = torch.tensor([0.0, 1.0, 0.0, 1.0], dtype=torch.float32)  # 2 blunders, 2 normal
        
        batch = (tensors, move_targets, attention_targets, is_blunder)
        
        # training_step returns loss
        loss = self.model.training_step(batch, 0)
        
        self.assertTrue(loss > 0)
        self.assertEqual(loss.shape, ())  # Scalar tensor

    def test_smoke_training_loop_run(self):
        """Run a single-epoch training run on sample PGN data to verify compile-to-disk logic."""
        sample_path = os.path.join(config.DATA_DIR, "sample_games.pgn")
        
        # Load sample dataset
        dataset = PGNDataset(sample_path, max_positions=50)
        self.assertGreater(len(dataset), 0, "Failed to load sample PGN games")
        
        # Create tiny loaders
        from torch.utils.data import DataLoader
        train_loader = DataLoader(dataset, batch_size=2, shuffle=True)
        val_loader = DataLoader(dataset, batch_size=2, shuffle=False)
        
        # Instantiate model with high learning rate just for testing
        test_model = DankFishModel(learning_rate=1e-2)
        
        # Run Trainer for 1 epoch
        trainer = L.Trainer(
            max_epochs=1,
            accelerator="cpu",
            logger=False,
            enable_checkpointing=False,
            enable_progress_bar=False
        )
        
        # Fit must run and succeed without errors
        trainer.fit(test_model, train_loader, val_loader)
        
        # Verify state_dict saving executes without errors
        constant_path = os.path.join(config.MODEL_DIR, "test_dankfish.ckpt")
        torch.save(test_model.state_dict(), constant_path)
        
        self.assertTrue(os.path.exists(constant_path))
        
        # Clean up
        if os.path.exists(constant_path):
            os.remove(constant_path)

if __name__ == "__main__":
    unittest.main()
