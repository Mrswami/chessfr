import sys
import os
import chess
from services.chess_api import ChessCrawler
from services.pattern_engine import PatternEngine

def clear_screen():
    os.system('cls' if os.name == 'nt' else 'clear')

def interactive_selection():
    clear_screen()
    print("========================================")
    print("   CHESS BEHAVIORAL: GAME SELECTOR")
    print("========================================\n")
    
    username = input("Enter Chess.com Username (e.g., Mrswami): ").strip()
    if not username:
        print("Username cannot be empty.")
        return

    crawler = ChessCrawler(username)
    engine = PatternEngine()

    print(f"\n[*] Fetching archives for {username}...")
    archives = crawler.get_monthly_archives()
    
    if not archives:
        print("[!] No archives found for this user.")
        return

    # For simplicity, focus on the latest month
    latest_month_url = archives[-1]
    print(f"[*] Loading games from {latest_month_url.split('/')[-2]}/{latest_month_url.split('/')[-1]}...")
    games = crawler.get_games_from_month(latest_month_url)

    if not games:
        print("[!] No games found in the latest month.")
        return

    while True:
        clear_screen()
        print(f"RECENT GAMES FOR: {username}")
        print("-" * 40)
        
        # Display list of games
        for i, game in enumerate(games[:15]): # Limit to latest 15 for CLI screen space
            white = game.get('white', {}).get('username', 'Unknown')
            black = game.get('black', {}).get('username', 'Unknown')
            result = game.get('url', '').split('/')[-1]
            print(f"[{i}] {white} vs {black} ({game.get('time_control')})")
        
        print("-" * 40)
        choice = input("\nEnter game index to ANALYZE (or 'q' to quit): ").strip().lower()
        
        if choice == 'q':
            break
        
        try:
            idx = int(choice)
            if 0 <= idx < len(games):
                selected_game = games[idx]
                pgn_text = selected_game.get('pgn', '')
                
                if not pgn_text:
                    print("[!] No PGN data found for this game.")
                    input("\nPress Enter to continue...")
                    continue

                print(f"\n[*] Analyzing game: {selected_game.get('url')}")
                
                # Load via python-chess
                pgn_io = io.StringIO(pgn_text)
                game_obj = chess.pgn.read_game(pgn_io)
                board = game_obj.board()
                
                # Logic: Find critical structural moments (Universe B)
                print("[*] Running Pattern Engine...")
                
                move_count = 0
                critical_moments = []
                
                for move in game_obj.mainline_moves():
                    # Calculate connectivity BEFORE move
                    score_before = engine.get_connectivity_score(board, board.turn)
                    
                    san = board.san(move)
                    board.push(move)
                    move_count += 1
                    
                    # Calculate connectivity AFTER move
                    score_after = engine.get_connectivity_score(board, not board.turn)
                    delta = score_after - score_before
                    
                    if abs(delta) > 1.5: # Significant structural change
                        critical_moments.append({
                            "move": move_count,
                            "san": san,
                            "delta": delta,
                            "final": score_after
                        })

                print(f"\n--- ANALYSIS COMPLETE ({move_count} moves) ---")
                if critical_moments:
                    print(f"Found {len(critical_moments)} structural 'swing' moments.")
                    for moment in critical_moments[:5]:
                        trend = "UP" if moment['delta'] > 0 else "DOWN"
                        print(f"  Move {moment['move']}: {moment['san']} -> Connectivity {trend} ({moment['delta']})")
                else:
                    print("This game was structurally stable.")
                
                print("\n[NEXT STEP] In a real session, this would be imported to Supabase.")
                input("\nPress Enter to go back to list...")
                
            else:
                print("Invalid index.")
                time.sleep(1)
        except ValueError:
            print("Please enter a valid number or 'q'.")
            time.sleep(1)
        except Exception as e:
            print(f"An error occurred: {e}")
            input("\nPress Enter to continue...")

import io
import time

if __name__ == "__main__":
    interactive_selection()
