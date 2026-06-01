import os

# Base directory paths
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_DIR = os.path.join(BASE_DIR, "models", "registry")
DATA_DIR = os.path.join(BASE_DIR, "data")

# Create directories if they do not exist
os.makedirs(MODEL_DIR, exist_ok=True)
os.makedirs(DATA_DIR, exist_ok=True)

# Tensor Shapes
BOARD_ROWS = 8
BOARD_COLS = 8
PIECE_CHANNELS = 12  # P, N, B, R, Q, K (White) + P, N, B, R, Q, K (Black)
EXTRA_CHANNELS = 6   # 1. White Protection, 2. Black Protection, 3. White Influence, 4. Black Influence, 5. White Cluster, 6. Black Cluster
PSYCH_CHANNELS = 2   # 1. Active Conflict Zone, 2. Threatened Unprotected Pieces
INPUT_CHANNELS = PIECE_CHANNELS + EXTRA_CHANNELS + PSYCH_CHANNELS  # 20 channels total

# Move Prediction Output Shape
# From-square (64) to To-square (64) = 4096 possible transitions.
# This represents a simplified, flat policy head for uci moves.
POLICY_OUTPUT_SIZE = 64 * 64

# Training Hyperparameters
BATCH_SIZE = 64
LEARNING_RATE = 1e-3
EPOCHS = 10
ELO_MIN = 1000
ELO_MAX = 1400

# Hybrid Dataset Configs
# Ratio of Lichess General games to AmateurSwami Personal games (e.g. 0.7 = 70% Lichess, 30% User)
LICHESS_RATIO = float(os.getenv("LICHESS_RATIO", "0.7"))
PERSONAL_GAMES_PATH = os.path.join(DATA_DIR, "personal_games.pgn")
LICHESS_GAMES_PATH = os.path.join(DATA_DIR, "lichess_games.pgn")

# API Settings
HOST = "0.0.0.0"
PORT = 8000
DEBUG = os.getenv("DEBUG", "False").lower() in ("true", "1", "t")
