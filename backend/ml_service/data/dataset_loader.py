import chess
import chess.pgn
import numpy as np
import io
import os
from typing import Tuple, List, Dict, Generator, Optional
from torch.utils.data import Dataset
from .pattern_engine import PatternEngine
import config

class DatasetLoader:
    """
    Utility class to convert chess positions into 20-channel Hybrid Board Tensors 
    and encode/decode chess moves to/from flat indices.
    """

    def __init__(self):
        self.engine = PatternEngine()
        # Map piece types to channel offsets
        # White: P=0, N=1, B=2, R=3, Q=4, K=5
        # Black: P=6, N=7, B=8, R=9, Q=10, K=11
        self.piece_to_offset = {
            chess.PAWN: 0,
            chess.KNIGHT: 1,
            chess.BISHOP: 2,
            chess.ROOK: 3,
            chess.QUEEN: 4,
            chess.KING: 5
        }

    def fen_to_hybrid_tensor(self, fen_or_board) -> np.ndarray:
        """
        Converts a FEN string or chess.Board into a 20-channel 8x8 representation:
        - Channels 0-5: White pieces (P, N, B, R, Q, K)
        - Channels 6-11: Black pieces (P, N, B, R, Q, K)
        - Channel 12: White Protection matrix (normalized)
        - Channel 13: Black Protection matrix (normalized)
        - Channel 14: White Influence matrix (normalized)
        - Channel 15: Black Influence matrix (normalized)
        - Channel 16: White Cluster matrix (normalized)
        - Channel 17: Black Cluster matrix (normalized)
        - Channel 18: Active Conflict Zone (Opponent's last move source=0.5, dest=1.0)
        - Channel 19: Threatened & Unprotected Friendly Pieces (1.0 if threatened and 0 defenders)
        """
        if isinstance(fen_or_board, str):
            board = chess.Board(fen_or_board)
        else:
            board = fen_or_board

        tensor = np.zeros((config.INPUT_CHANNELS, config.BOARD_ROWS, config.BOARD_COLS), dtype=np.float32)
        turn = board.turn

        # 1. Populate Piece Placement Channels (0-11)
        for square in chess.SQUARES:
            piece = board.piece_at(square)
            if piece:
                row = 7 - (square // 8)
                col = square % 8
                
                color_offset = 0 if piece.color == chess.WHITE else 6
                piece_offset = self.piece_to_offset[piece.piece_type]
                channel = color_offset + piece_offset
                
                tensor[channel, row, col] = 1.0

        # 2. Populate Connectivity / Tabiya Channels (12-17)
        tensor[12, :, :] = self.engine.get_protection_matrix(board, chess.WHITE) / 4.0
        tensor[13, :, :] = self.engine.get_protection_matrix(board, chess.BLACK) / 4.0
        tensor[14, :, :] = self.engine.get_influence_matrix(board, chess.WHITE) / 8.0
        tensor[15, :, :] = self.engine.get_influence_matrix(board, chess.BLACK) / 8.0
        tensor[16, :, :] = self.engine.get_cluster_matrix(board, chess.WHITE) / 16.0
        tensor[17, :, :] = self.engine.get_cluster_matrix(board, chess.BLACK) / 16.0

        # 3. Channel 18: Active Conflict Zone (Opponent's last move)
        # Represents where attention is focused due to the immediate threat
        if board.move_stack:
            last_move = board.peek()
            from_sq = last_move.from_square
            to_sq = last_move.to_square
            
            from_row, from_col = 7 - (from_sq // 8), from_sq % 8
            to_row, to_col = 7 - (to_sq // 8), to_sq % 8
            
            tensor[18, from_row, from_col] = 0.5
            tensor[18, to_row, to_col] = 1.0

        # 4. Channel 19: Threatened & Unprotected Friendly Pieces
        # Highlights vulnerable pieces where Loss Aversion might occur
        for square in chess.SQUARES:
            piece = board.piece_at(square)
            if piece and piece.color == turn:
                # Is under threat by opponent?
                is_threatened = board.is_attacked_by(not turn, square)
                if is_threatened:
                    # Do friendly pieces protect it?
                    protectors = board.attackers(turn, square)
                    if len(protectors) == 0:
                        row, col = 7 - (square // 8), square % 8
                        tensor[19, row, col] = 1.0

        return tensor

    @staticmethod
    def encode_move(move: chess.Move) -> int:
        """
        Encodes a chess move into an integer index [0..4095] for policy head output.
        Index = from_square * 64 + to_square
        """
        return move.from_square * 64 + move.to_square

    @staticmethod
    def decode_move(index: int, board: Optional[chess.Board] = None) -> chess.Move:
        """
        Decodes an integer index back into a chess.Move.
        Handles default Queen promotion if the move is a promoting pawn move.
        """
        from_square = index // 64
        to_square = index % 64
        
        move = chess.Move(from_square, to_square)
        
        if board:
            piece = board.piece_at(from_square)
            if piece and piece.piece_type == chess.PAWN:
                to_rank = to_square // 8
                if (piece.color == chess.WHITE and to_rank == 7) or \
                   (piece.color == chess.BLACK and to_rank == 0):
                    move.promotion = chess.QUEEN
        
        return move


class PGNDataset(Dataset):
    """
    PyTorch Dataset that loads both general and personal PGN logs,
    supporting manual ratio partitioning and custom blunder heuristics.
    
    Returns training samples containing:
    1. Input tensor: (20, 8, 8) board representation
    2. Move index: int target class
    3. Attention target: (64,) focus zone heatmap
    4. Blunder weight: float32 loss scaling factor
    """

    def __init__(self, pgn_path: str, elo_min: int = 1000, elo_max: int = 1400, max_positions: int = 50000):
        self.loader = DatasetLoader()
        self.positions: List[Tuple[np.ndarray, int, np.ndarray, float]] = []
        self._load_pgn(pgn_path, elo_min, elo_max, max_positions)

    def _load_pgn(self, pgn_path: str, elo_min: int, elo_max: int, max_positions: int):
        """Parses the PGN file to extract training pairs."""
        if not os.path.exists(pgn_path):
            print(f"Warning: PGN file {pgn_path} not found. Starting with empty dataset.")
            return

        engine = PatternEngine()

        try:
            with open(pgn_path, "r", encoding="utf-8") as f:
                while len(self.positions) < max_positions:
                    game = chess.pgn.read_game(f)
                    if game is None:
                        break

                    white_elo_str = game.headers.get("WhiteElo", "?")
                    black_elo_str = game.headers.get("BlackElo", "?")
                    
                    try:
                        white_elo = int(white_elo_str)
                        black_elo = int(black_elo_str)
                    except ValueError:
                        continue

                    # Filter based on target Elos
                    white_in_range = elo_min <= white_elo <= elo_max
                    black_in_range = elo_min <= black_elo <= elo_max

                    if not (white_in_range or black_in_range):
                        continue

                    board = game.board()
                    for node in game.mainline():
                        move = node.move
                        turn = board.turn
                        
                        player_in_range = (turn == chess.WHITE and white_in_range) or \
                                          (turn == chess.BLACK and black_in_range)
                        
                        if player_in_range:
                            # 1. Generate Input Tensor
                            tensor = self.loader.fen_to_hybrid_tensor(board)
                            
                            # 2. Encode target move
                            move_idx = DatasetLoader.encode_move(move)
                            
                            # 3. Generate Ground-Truth Attention Focus target
                            # Set destination and source of move to 1.0 in attention map
                            attention_target = np.zeros(64, dtype=np.float32)
                            attention_target[move.from_square] = 1.0
                            attention_target[move.to_square] = 1.0
                            
                            # 4. Assess if this move was a Blunder (for custom loss weighting)
                            is_blunder = 0.0
                            # A: Check PGN annotation symbols like ? or ??
                            nags = node.nags
                            if 2 in nags or 4 in nags or 6 in nags:  # NAGs: 2=?, 4=??, 6=!?
                                is_blunder = 1.0
                            else:
                                # B: Check local pattern engine connectivity drop (heuristic)
                                prev_connectivity = engine.get_connectivity_score(board, turn)
                                board.push(move)
                                new_connectivity = engine.get_connectivity_score(board, turn)
                                board.pop()
                                
                                connectivity_drop = prev_connectivity - new_connectivity
                                if connectivity_drop >= 1.5:  # Significant drop in cluster strength
                                    is_blunder = 1.0

                            self.positions.append((tensor, move_idx, attention_target, is_blunder))
                            
                            if len(self.positions) >= max_positions:
                                break

                        board.push(move)
        except Exception as e:
            print(f"Error reading PGN {pgn_path}: {str(e)}")

    @classmethod
    def load_hybrid_dataset(cls, lichess_path: str, personal_path: str, lichess_ratio: float = 0.7, max_positions: int = 50000):
        """
        Creates a combined dataset using configured ratio.
        Example: 0.7 means 70% General Lichess, 30% Personal games.
        """
        lichess_limit = int(max_positions * lichess_ratio)
        personal_limit = max_positions - lichess_limit

        print(f"Loading hybrid dataset: target {lichess_limit} Lichess, {personal_limit} Personal positions.")
        
        # Load datasets
        lichess_ds = cls(lichess_path, max_positions=lichess_limit)
        personal_ds = cls(personal_path, max_positions=personal_limit)
        
        # Combine
        combined = cls.__new__(cls)
        combined.loader = DatasetLoader()
        combined.positions = lichess_ds.positions + personal_ds.positions
        
        print(f"Hybrid dataset compiled with {len(combined.positions)} total positions.")
        return combined

    def __len__(self) -> int:
        return len(self.positions)

    def __getitem__(self, idx: int) -> Tuple[np.ndarray, int, np.ndarray, float]:
        tensor, move_idx, attention, is_blunder = self.positions[idx]
        return tensor, move_idx, attention, is_blunder
