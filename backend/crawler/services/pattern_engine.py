import chess
import chess.pgn
import io
from typing import List, Dict, Set, Tuple

class PatternEngine:
    """
    Universe B Logic: Analyzes chess positions for structural 'Connectivity'.
    Instead of raw engine evaluations, this engine measures how well 
    pieces are networked and how fragmented the position is.
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

    def rank_moves_by_connectivity(self, board: chess.Board) -> List[Dict]:
        """
        Ranks all legal moves based on the DELTA in Connectivity Score.
        """
        ranked_moves = []
        original_score = self.get_connectivity_score(board, board.turn)
        
        for move in board.legal_moves:
            san = board.san(move)
            board.push(move)
            # We evaluate from the perspective of the player who just moved
            new_score = self.get_connectivity_score(board, not board.turn)
            delta = new_score - original_score
            
            ranked_moves.append({
                "uci": move.uci(),
                "san": san,
                "connectivity_delta": round(delta, 2),
                "final_score": new_score
            })
            board.pop()
            
        # Sort by delta (highest first)
        return sorted(ranked_moves, key=lambda x: x["connectivity_delta"], reverse=True)

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
        Groups pieces into 'Clusters' based on mutual protection or proximity.
        Uses an iterative approach to prevent recursion depth issues.
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

if __name__ == "__main__":
    # Test on a classic fragmented vs connected position
    engine = PatternEngine()
    
    # Starting position (Very connected)
    board = chess.Board()
    print(f"Starting Position Connectivity: {engine.get_connectivity_score(board, chess.WHITE)}")
    
    # Rank moves for white
    top_moves = engine.rank_moves_by_connectivity(board)[:5]
    print("\nTop 5 Connectivity Moves:")
    for m in top_moves:
        print(f"  {m['san']}: Delta {m['connectivity_delta']} (Final: {m['final_score']})")

    # Test an artificial 'Fragmented' position (Isolated pieces)
    fragmented_fen = "4k3/8/8/8/8/P7/8/R3K2R w KQ - 0 1"
    board_frag = chess.Board(fragmented_fen)
    print(f"\nFragmented Position Connectivity: {engine.get_connectivity_score(board_frag, chess.WHITE)}")
    clusters = engine._identify_clusters(board_frag, chess.WHITE)
    print(f"Clusters found: {len(clusters)} (Expect 3: a3, e1, a1/h1/e1 overlap etc.)")
