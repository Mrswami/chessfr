import os
import sys
from services.chess_api import ChessCrawler

def main(username: str):
    """
    Main entry point for the backend crawler.
    Initially, this just demonstrates the fetching of data.
    Later, it will be the orchestration service that:
    1. Fetches a list of games for the UI to display.
    2. Performs analysis on the user-selected game.
    """
    
    # 1. Initialize the Crawler with your identity
    crawler = ChessCrawler(username=username)
    
    print(f"--- Behavioral Fetch started for {username} ---")
    
    # 2. Get the latest month of games (for the selection UI)
    archives = crawler.get_monthly_archives()
    if not archives:
        print("No historical data found.")
        return
    
    latest_month = archives[-1]
    games = crawler.get_games_from_month(latest_month)
    
    print(f"[{username}] Found {len(games)} games in the latest archive month.")
    print("This metadata will be passed back to the Flutter UI for selection.")
    
    # Example selection log (User would do this via the App later)
    # The 'Ingestion' would only happen if user clicks 'IMPORT'
    # For now, let's show what a 'Clean' game looks like
    for game in games[:2]:
        print(f"\nPotential game for training:")
        print(f"  Result: {game.get('url')}")
        print(f"  PGN snippet: {game.get('pgn', '')[:100]}...")

if __name__ == "__main__":
    # Default to 'Mrswami' unless a username is passed via CLI
    user = sys.argv[1] if len(sys.argv) > 1 else "Mrswami"
    main(user)
