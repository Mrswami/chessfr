import os
import argparse
import torch
from torch.utils.data import DataLoader, random_split
import lightning as L
from lightning.pytorch.callbacks import ModelCheckpoint

import sys
# Ensure the root of ml_service is on the python path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import config
from data.dataset_loader import PGNDataset
from models.architecture import DankFishModel

def main():
    parser = argparse.ArgumentParser(description="DankFish Neural Network Training Pipeline")
    parser.add_argument("--lichess_pgn", type=str, default=config.LICHESS_GAMES_PATH, help="Path to lichess games PGN")
    parser.add_argument("--personal_pgn", type=str, default=config.PERSONAL_GAMES_PATH, help="Path to personal games PGN")
    parser.add_argument("--epochs", type=int, default=config.EPOCHS, help="Number of training epochs")
    parser.add_argument("--batch_size", type=int, default=config.BATCH_SIZE, help="DataLoader batch size")
    parser.add_argument("--ratio", type=float, default=config.LICHESS_RATIO, help="Ratio of Lichess to personal games")
    parser.add_argument("--max_positions", type=int, default=10000, help="Limit max positions loaded to save RAM")
    parser.add_argument("--lr", type=float, default=config.LEARNING_RATE, help="Learning rate")
    args = parser.parse_args()

    print("--- Booting up DankFish Training Loop ---")
    
    # 1. Ingest datasets using user-configured Hybrid splits
    if os.path.exists(args.lichess_pgn) or os.path.exists(args.personal_pgn):
        dataset = PGNDataset.load_hybrid_dataset(
            lichess_path=args.lichess_pgn,
            personal_path=args.personal_pgn,
            lichess_ratio=args.ratio,
            max_positions=args.max_positions
        )
    else:
        # Fallback to local sample file if others are missing (e.g. local tests)
        sample_path = os.path.join(config.DATA_DIR, "sample_games.pgn")
        print(f"Lichess or Personal PGN not found. Falling back to sample database: {sample_path}")
        dataset = PGNDataset(sample_path, max_positions=args.max_positions)

    if len(dataset) == 0:
        print("Error: Dataset is empty! Cannot run training. Please verify PGN paths.")
        return

    # 2. Split dataset into Train and Validation sets (80/20)
    val_size = int(len(dataset) * 0.2)
    train_size = len(dataset) - val_size
    train_set, val_set = random_split(dataset, [train_size, val_size])

    print(f"Dataset split: {train_size} training samples, {val_size} validation samples.")

    # 3. Create loaders
    # We use num_workers=0 to ensure compatibility across Docker and Windows platforms
    train_loader = DataLoader(train_set, batch_size=args.batch_size, shuffle=True, num_workers=0)
    val_loader = DataLoader(val_set, batch_size=args.batch_size, shuffle=False, num_workers=0)

    # 4. Initialize DankFish Model wrapper
    model = DankFishModel(learning_rate=args.lr)

    # 5. Define callbacks to save model weights
    checkpoint_callback = ModelCheckpoint(
        dirpath=config.MODEL_DIR,
        filename="dankfish_baseline",
        save_top_k=1,
        monitor="val_loss",
        mode="min"
    )

    # 6. Initialize Lightning Trainer
    # Runs on CPU by default for cheap container deployments, easily scales to GPU
    trainer = L.Trainer(
        max_epochs=args.epochs,
        accelerator="auto",
        devices=1,
        callbacks=[checkpoint_callback],
        enable_progress_bar=True
    )

    # 7. Execute training loop
    print("Training neural network...")
    trainer.fit(model, train_loader, val_loader)

    print(f"--- Training Complete ---")
    best_path = checkpoint_callback.best_model_path
    if best_path:
        print(f"Best model saved to: {best_path}")
        
        # Save a duplicate at a constant path in registry for inference loading
        constant_path = os.path.join(config.MODEL_DIR, "dankfish_baseline.ckpt")
        torch.save(model.state_dict(), constant_path)
        print(f"Saved weights state_dict for deployment: {constant_path}")
    else:
        print("Warning: No model checkpoint was saved.")

if __name__ == "__main__":
    main()
