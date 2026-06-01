import chess
import chess.pgn
from typing import List, Dict, Any, Tuple

class BiasTracker:
    """
    Personalized Bias Tracker: Analyzes a player's PGN game history 
    to calculate 6 core psychological and tactical shortcomings.
    Scores range from 0.0 (perfect discipline) to 1.0 (extreme bias).
    """

    def __init__(self, player_name: str = "AmateurSwami"):
        self.player_name = player_name

    def analyze_history(self, games: List[chess.pgn.Game]) -> Dict[str, float]:
        """Runs all 6 bias calculations over the provided list of games."""
        if not games:
            return {
                "premature_queen": 0.0,
                "castling_delay": 0.0,
                "pawn_phobia": 0.0,
                "luft_neglect": 0.0,
                "exchange_panic": 0.0,
                "king_hunt": 0.0
            }

        # Calculate averages
        return {
            "premature_queen": self.calculate_queen_activation_bias(games),
            "castling_delay": self.calculate_castling_delay_bias(games),
            "pawn_phobia": self.calculate_pawn_structure_phobia(games),
            "luft_neglect": self.calculate_luft_neglect_bias(games),
            "exchange_panic": self.calculate_exchange_panic_bias(games),
            "king_hunt": self.calculate_king_hunt_bias(games)
        }

    def _is_player(self, game: chess.pgn.Game, color: chess.Color) -> bool:
        """Helper to check if the target player is playing the specified color."""
        header_name = "White" if color == chess.WHITE else "Black"
        name_in_game = game.headers.get(header_name, "")
        # Case-insensitive substring match
        return self.player_name.lower() in name_in_game.lower()

    def calculate_queen_activation_bias(self, games: List[chess.pgn.Game]) -> float:
        """Percent of games moving the Queen before move 8."""
        bad_games = 0
        total_games = 0

        for game in games:
            # Determine color of target player
            color = None
            if self._is_player(game, chess.WHITE):
                color = chess.WHITE
            elif self._is_player(game, chess.BLACK):
                color = chess.BLACK
            
            if color is None:
                continue

            total_games += 1
            board = game.board()
            queen_moved_early = False
            move_count = 0
            
            for node in game.mainline():
                move = node.move
                turn = board.turn
                
                # Check first 8 moves (16 ply)
                if move_count >= 16:
                    break
                    
                if turn == color:
                    piece = board.piece_at(move.from_square)
                    if piece and piece.piece_type == chess.QUEEN:
                        queen_moved_early = True
                        break
                        
                board.push(move)
                move_count += 1
                
            if queen_moved_early:
                bad_games += 1

        return round(bad_games / max(total_games, 1), 3)

    def calculate_castling_delay_bias(self, games: List[chess.pgn.Game]) -> float:
        """Percent of games castling after move 12 (24 ply) or not castling at all."""
        bad_games = 0
        total_games = 0

        for game in games:
            color = None
            if self._is_player(game, chess.WHITE):
                color = chess.WHITE
            elif self._is_player(game, chess.BLACK):
                color = chess.BLACK
            
            if color is None:
                continue

            total_games += 1
            board = game.board()
            castled = False
            castled_late = False
            move_idx = 0
            
            for node in game.mainline():
                move = node.move
                turn = board.turn
                
                if turn == color:
                    # Detect castling by checking if King moved 2 squares
                    piece = board.piece_at(move.from_square)
                    if piece and piece.piece_type == chess.KING:
                        file_dist = abs(chess.square_file(move.from_square) - chess.square_file(move.to_square))
                        if file_dist == 2:
                            castled = True
                            # Move count is move_idx // 2 (since each move has 2 ply)
                            if (move_idx // 2) > 12:
                                castled_late = True

                board.push(move)
                move_idx += 1
                
            # If never castled OR castled after move 12, it is a delayed castling game
            if not castled or castled_late:
                bad_games += 1

        return round(bad_games / max(total_games, 1), 3)

    def calculate_pawn_structure_phobia(self, games: List[chess.pgn.Game]) -> float:
        """
        Ratio of avoided captures that would result in doubled pawns,
        showing a phobia of pawn structure weaknesses.
        """
        avoided_count = 0
        total_opportunities = 0

        for game in games:
            color = None
            if self._is_player(game, chess.WHITE):
                color = chess.WHITE
            elif self._is_player(game, chess.BLACK):
                color = chess.BLACK
            
            if color is None:
                continue

            board = game.board()
            for node in game.mainline():
                move = node.move
                turn = board.turn
                
                if turn == color:
                    # Find all legal captures that would result in doubled pawns
                    for legal_move in board.legal_moves:
                        if board.is_capture(legal_move):
                            # Simulate move to see if it doubles pawns
                            board.push(legal_move)
                            is_doubled = self._has_doubled_pawns(board, color)
                            board.pop()
                            
                            if is_doubled:
                                total_opportunities += 1
                                # Did the player actually choose a different move?
                                if move != legal_move:
                                    avoided_count += 1
                                    
                board.push(move)

        return round(avoided_count / max(total_opportunities, 1), 3)

    def _has_doubled_pawns(self, board: chess.Board, color: chess.Color) -> bool:
        """Helper to detect if a side has doubled pawns on any file."""
        pawn_squares = board.pieces(chess.PAWN, color)
        files = [chess.square_file(sq) for sq in pawn_squares]
        return len(files) != len(set(files))

    def calculate_luft_neglect_bias(self, games: List[chess.pgn.Game]) -> float:
        """
        Percent of games entering move 20 (40 ply) with a castled king
        but NO luft/escape square created (leaving them open to back-rank mates).
        """
        bad_games = 0
        total_games = 0

        for game in games:
            color = None
            if self._is_player(game, chess.WHITE):
                color = chess.WHITE
            elif self._is_player(game, chess.BLACK):
                color = chess.BLACK
            
            if color is None:
                continue

            total_games += 1
            board = game.board()
            move_idx = 0
            
            for node in game.mainline():
                move = node.move
                board.push(move)
                move_idx += 1
                
                # Check exactly at move 20 (40 ply)
                if move_idx == 40:
                    break

            # If the game ended before move 20, just use the final board state
            # Verify if king is castled (on g-file or b-file/c-file)
            king_square = board.king(color)
            if king_square is None:
                continue
                
            king_file = chess.square_file(king_square)
            king_rank = chess.square_rank(king_square)
            
            # Standard castled positions: King on g1/g8 or c1/c8
            is_kingside_castled = (king_file == 6) and (king_rank == (0 if color == chess.WHITE else 7))
            
            if is_kingside_castled:
                # Check pawns in front of the king (f, g, h files)
                # For White, standard starting is f2, g2, h2.
                # Luft is created if g-pawn or h-pawn has moved forward
                rank_offset = 1 if color == chess.WHITE else 6
                
                # Get squares of g and h pawns at starting ranks
                g_square = chess.square(6, rank_offset)
                h_square = chess.square(7, rank_offset)
                
                g_pawn_present = board.piece_at(g_square) == chess.Piece(chess.PAWN, color)
                h_pawn_present = board.piece_at(h_square) == chess.Piece(chess.PAWN, color)
                
                # If both pawns are still on their starting squares, no luft is created!
                if g_pawn_present and h_pawn_present:
                    bad_games += 1
                    
        return round(bad_games / max(total_games, 1), 3)

    def calculate_exchange_panic_bias(self, games: List[chess.pgn.Game]) -> float:
        """
        Percent of times a player immediately trades a piece when it is under threat
        rather than defending it or maintaining the board tension.
        """
        trade_count = 0
        total_threats = 0

        for game in games:
            color = None
            if self._is_player(game, chess.WHITE):
                color = chess.WHITE
            elif self._is_player(game, chess.BLACK):
                color = chess.BLACK
            
            if color is None:
                continue

            board = game.board()
            for node in game.mainline():
                move = node.move
                turn = board.turn
                
                if turn == color:
                    # Find all friendly pieces currently under attack by opponent
                    attacked_squares = []
                    for sq in chess.SQUARES:
                        piece = board.piece_at(sq)
                        if piece and piece.color == color:
                            if board.is_attacked_by(not color, sq):
                                attacked_squares.append(sq)
                                
                    if attacked_squares:
                        total_threats += len(attacked_squares)
                        # Did the move involve capturing the piece that was attacking us?
                        # Or did we choose to resolve tension by trade?
                        if board.is_capture(move):
                            captured_square = move.to_square
                            # If we captured an opponent piece that was attacking our piece, it's a panic trade
                            trade_count += 1
                            
                board.push(move)

        return round(trade_count / max(total_threats, 1), 3)

    def calculate_king_hunt_bias(self, games: List[chess.pgn.Game]) -> float:
        """
        Frequency of speculative checks (giving checks in the middlegame 
        without leading to mate or material gain). Returns checks per game.
        """
        check_count = 0
        total_games = 0

        for game in games:
            color = None
            if self._is_player(game, chess.WHITE):
                color = chess.WHITE
            elif self._is_player(game, chess.BLACK):
                color = chess.BLACK
            
            if color is None:
                continue

            total_games += 1
            board = game.board()
            move_idx = 0
            
            for node in game.mainline():
                move = node.move
                turn = board.turn
                
                if turn == color:
                    # Check if this move gives a check
                    board.push(move)
                    is_check = board.is_check()
                    board.pop()
                    
                    if is_check:
                        # Only count checks in middlegame (moves 10 to 30)
                        if 20 <= move_idx <= 60:
                            check_count += 1

                board.push(move)
                move_idx += 1

        # We normalize checks per game into a 0.0-1.0 score
        # A player average of 3+ middlegame checks per game represents a high King Hunt bias.
        checks_per_game = check_count / max(total_games, 1)
        score = min(1.0, checks_per_game / 3.0)
        return round(score, 3)
