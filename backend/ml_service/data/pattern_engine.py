import chess
from typing import List, Dict, Set, Tuple
import numpy as np

class PatternEngine:
    """
    Universe B Logic: Analyzes chess positions for structural 'Connectivity'.
    Instead of raw engine evaluations, this engine measures how well 
    pieces are networked and how fragmented the position is.
    
    Adapted for feature engineering, providing 8x8 matrix representations of:
    - Protection networks
    - Control/Influence maps
    - Fragmented piece clusters (tabiya structures)
    """

    def __init__(self):
        # Weighting factors for the Connectivity Score (C_s)
        self.weights = {
            "protection": 1.0,    # Piece A protects Piece B
            "overlap": 0.5,       # Piece A and B influence the same square
            "centralization": 0.3, # Piece is in the 'Quad-Split' center
            "isolation_penalty": -2.0 # Piece has no connection to its team
        }

    def get_connectivity_score(self, board: chess.Board, color: chess.Color) -> float:
        """
        Calculates the Connectivity Score (C_s) for a given side.
        C_s = (Sum of networked influences) - (Penalty for isolated clusters)
        """
        score = 0.0
        pieces = board.piece_map()
        friendly_pieces = {pos: piece for pos, piece in pieces.items() if piece.color == color}
        
        # 1. Protection & Influence Overlap
        influence_map = self._get_influence_map(board, color)
        
        for pos, piece in friendly_pieces.items():
            # Does this piece have 'friends' nearby?
            protectors = board.attackers(color, pos)
            score += len(protectors) * self.weights["protection"]
            
            # Is this piece contributing to a 'Networked' square?
            for square in board.attacks(pos):
                if square in influence_map and len(influence_map[square]) > 1:
                    score += self.weights["overlap"]

        # 2. Fragmented Cluster Penalty
        clusters = self._identify_clusters(board, color)
        if len(clusters) > 1:
            # More clusters = more fragmentation
            score += (len(clusters) - 1) * self.weights["isolation_penalty"]

        return round(score, 2)

    def get_protection_matrix(self, board: chess.Board, color: chess.Color) -> np.ndarray:
        """
        Returns an 8x8 matrix where each square occupied by a friendly piece 
        contains the count of friendly pieces protecting/guarding it.
        """
        matrix = np.zeros((8, 8), dtype=np.float32)
        for square in chess.SQUARES:
            piece = board.piece_at(square)
            if piece and piece.color == color:
                protectors = board.attackers(color, square)
                row, col = 7 - (square // 8), square % 8  # Chess standard: Rank 8 is row 0
                matrix[row, col] = float(len(protectors))
        return matrix

    def get_influence_matrix(self, board: chess.Board, color: chess.Color) -> np.ndarray:
        """
        Returns an 8x8 matrix containing the count of active attacks/control 
        on each square by pieces of the specified color.
        """
        matrix = np.zeros((8, 8), dtype=np.float32)
        for square in chess.SQUARES:
            attackers = board.attackers(color, square)
            row, col = 7 - (square // 8), square % 8
            matrix[row, col] = float(len(attackers))
        return matrix

    def get_cluster_matrix(self, board: chess.Board, color: chess.Color) -> np.ndarray:
        """
        Returns an 8x8 matrix where each square occupied by a piece contains 
        the total size (number of pieces) of the cooperative cluster it belongs to.
        Isolated pieces will have a value of 1.0. Empty squares have 0.0.
        This represents how well integrated a piece is in the tabiya.
        """
        matrix = np.zeros((8, 8), dtype=np.float32)
        clusters = self._identify_clusters(board, color)
        
        for cluster in clusters:
            cluster_size = float(len(cluster))
            for square in cluster:
                row, col = 7 - (square // 8), square % 8
                matrix[row, col] = cluster_size
        return matrix

    def _get_influence_map(self, board: chess.Board, color: chess.Color) -> Dict[int, Set[int]]:
        """Maps squares to the set of friendly pieces controlling them."""
        influence = {}
        for square in chess.SQUARES:
            attackers = board.attackers(color, square)
            if attackers:
                influence[square] = set(attackers)
        return influence

    def _identify_clusters(self, board: chess.Board, color: chess.Color) -> List[Set[int]]:
        """
        Groups friendly pieces into 'Clusters' based on mutual protection.
        """
        pieces = [pos for pos, p in board.piece_map().items() if p.color == color]
        clusters = []
        visited = set()

        for start_pos in pieces:
            if start_pos in visited:
                continue
            
            # Start a new cluster
            new_cluster = set()
            stack = [start_pos]
            
            while stack:
                pos = stack.pop()
                if pos in visited:
                    continue
                
                visited.add(pos)
                new_cluster.add(pos)
                
                # Find connected 'friends'
                for friend_pos in pieces:
                    if friend_pos in visited:
                        continue
                        
                    # Connection condition: Mutual protection
                    # A protects B or B protects A
                    is_connected = (pos in board.attackers(color, friend_pos)) or \
                                   (friend_pos in board.attackers(color, pos))
                    
                    if is_connected:
                        stack.append(friend_pos)
            
            clusters.append(new_cluster)
        
        return clusters
