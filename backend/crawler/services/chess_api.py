import requests
import time
import random
from typing import List, Dict, Optional

class ChessCrawler:
    """
    A professional, polite crawler for the Chess Behavioral Project.
    Adheres to Chess.com's Published Data API (PubAPI) standards.
    """

    BASE_URL = "https://api.chess.com/pub/player"
    
    def __init__(self, username: str, email: str = "jacobfluttereddev@gmail.com"):
        self.username = username
        self.email = email
        self.user_agent = f"ChessBehavioralProject/1.0 (Contact: {self.email})"
        self.headers = {
            "User-Agent": self.user_agent
        }

    def _get(self, url: str) -> Optional[Dict]:
        """Base GET with polite rate limiting."""
        # Politeness delay: Respect the platform's resources
        time.sleep(random.uniform(1.0, 2.5)) 
        
        try:
            response = requests.get(url, headers=self.headers)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            print(f"Error fetching data from {url}: {e}")
            return None

    def get_monthly_archives(self) -> List[str]:
        """Returns a list of URLs for each month the user has played."""
        url = f"{self.BASE_URL}/{self.username}/games/archives"
        data = self._get(url)
        return data.get("archives", []) if data else []

    def get_games_from_month(self, archive_url: str) -> List[Dict]:
        """
        Fetches metadata for all games in a specific month.
        This allows the user to 'browse' their history and pick games.
        """
        data = self._get(archive_url)
        if not data:
            return []
        
        # We return a list of games for the UI to display
        # Metadata includes: opponent, result, date, and game URL
        return data.get("games", [])

    def fetch_specific_game_pgn(self, game_url: str) -> Optional[str]:
        """
        Fetches the PGN for a specific game the user has selected.
        This avoids bulk downloading unnecessary 'fluke' games.
        """
        # Note: The PubAPI already returns the PGN in the archive response,
        # but this method allows for precise fetching if needed.
        pass

if __name__ == "__main__":
    # Test with your username (replace 'erik' with yours)
    crawler = ChessCrawler("Mrswami")
    print(f"--- Fetching Archives for {crawler.username} ---")
    archives = crawler.get_monthly_archives()
    
    if archives:
        print(f"Found {len(archives)} months of history.")
        # Let's peek at the most recent month
        latest_month_url = archives[-1]
        print(f"Inspecting: {latest_month_url}")
        
        games = crawler.get_games_from_month(latest_month_url)
        print(f"Found {len(games)} games in the latest month.")
        
        # Print first few for verification
        for game in games[:3]:
            print(f"- {game.get('end_time')} | Opponent: {game.get('white', {}).get('username')} vs {game.get('black', {}).get('username')}")
    else:
        print("No archives found or user does not exist.")
