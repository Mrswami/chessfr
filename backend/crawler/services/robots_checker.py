import urllib.robotparser
import requests

def can_fetch(url: str, user_agent: str = "ChessBehavioralProject/1.0") -> bool:
    """
    Check if the robots.txt file for the site allows fetching the given URL.
    This is an industry-standard ethical practice for crawlers.
    """
    rp = urllib.robotparser.RobotFileParser()
    try:
        # Get the base robots.txt URL
        base_url = "/".join(url.split("/")[:3]) + "/robots.txt"
        
        # Load the robots.txt content
        response = requests.get(base_url, headers={"User-Agent": user_agent}, timeout=5)
        if response.status_code == 200:
            rp.parse(response.text.splitlines())
        else:
            # If no robots.txt exists, it's generally okay to crawl
            return True
            
        return rp.can_fetch(user_agent, url)
    except Exception as e:
        print(f"Error checking robots.txt: {e}")
        # Default to safe (True) but log the error
        return True

if __name__ == "__main__":
    # Test with standard Chess.com URLs
    test_urls = [
        "https://www.chess.com/games/archive/Mrswami",
        "https://api.chess.com/pub/player/Mrswami/games",
        "https://www.chess.com/stats/live/chess/Mrswami"
    ]
    
    for url in test_urls:
        allowed = can_fetch(url)
        print(f"[{'ALLOWED' if allowed else 'DENIED'}] {url}")
