import os
import re
import json

# Define absolute paths in the workspace
WORKSPACE_DIR = r"c:\Users\freem\Documents\ChessFr"
RAW_DUMP_PATH = os.path.join(WORKSPACE_DIR, "data", "notebook_imports", "raw_dump.txt")
PGN_OUTPUT_PATH = os.path.join(WORKSPACE_DIR, "data", "notebook_imports", "extracted_games.pgn")
TOPIC_JSON_PATH = os.path.join(WORKSPACE_DIR, "data", "notebook_imports", "topic_relevance.json")

# Core topics we want to track relevance and frequency for
KEYWORDS = {
    "P-CBA Protocol": [r"\bp-cba\b", r"\bpcba\b"],
    "NoSQL & DB Architecture": [r"\bnosql\b", r"\bjson\b", r"\bschema\b", r"\bdatabase\b"],
    "Red Mist & Impulsivity": [r"\bred mist\b", r"\bred-mist\b", r"\bimpulsive\b", r"\bblunder\b"],
    "Strategic Openings": [r"\bsicilian\b", r"\blondon\b", r"\bbenko\b", r"\bbenoni\b", r"\bqga\b"],
    "Land Management Tangents": [r"\bland management\b", r"\bbureau of land\b", r"\bblm\b"],
    "Sleeping Phoenix": [r"\bsleeping phoenix\b", r"\bhigh-entropy\b", r"\bentropy\b"]
}

def parse_and_sync():
    print("--- Starting Google LLM Notebook Context Sync ---")
    
    if not os.path.exists(RAW_DUMP_PATH):
        print(f"[!] Error: No raw transcript file found at: {RAW_DUMP_PATH}")
        print("Please create this file and paste your Google Notebook transcripts into it.")
        return
        
    with open(RAW_DUMP_PATH, "r", encoding="utf-8") as f:
        content = f.read()
        
    # Ensure output directories exist
    os.makedirs(os.path.dirname(PGN_OUTPUT_PATH), exist_ok=True)
    
    # 1. Parse Conversational Context Metrics (Keywords & Topics)
    topic_scores = {}
    total_words = len(content.split())
    
    for topic, patterns in KEYWORDS.items():
        count = 0
        for pattern in patterns:
            matches = re.findall(pattern, content, re.IGNORECASE)
            count += len(matches)
        topic_scores[topic] = count
        
    print(f"[*] Processed {total_words} words from raw transcript.")
    print("[*] Conversational Topic Frequencies:")
    for topic, count in topic_scores.items():
        print(f"    - {topic}: {count} occurrences")
        
    # Write topic metrics
    metrics_payload = {
        "metadata": {
            "total_words_analyzed": total_words,
            "source_file": "raw_dump.txt"
        },
        "topic_frequencies": topic_scores
    }
    
    with open(TOPIC_JSON_PATH, "w", encoding="utf-8") as f:
        json.dump(metrics_payload, f, indent=4)
    print(f"[+] Saved conversation metrics to: {TOPIC_JSON_PATH}")

    # 2. Extract PGN games from the dump
    # A standard PGN starts with tags like [Event "..."] and ends with a result like 1-0 or *
    pgn_pattern = r"(\[Event\s+\"[^\"]+\"\][\s\S]*?(?:\*|1-0|0-1|1/2-1/2))"
    pgns = re.findall(pgn_pattern, content)
    
    if pgns:
        print(f"[+] Found {len(pgns)} PGN games in the transcript.")
        with open(PGN_OUTPUT_PATH, "w", encoding="utf-8") as f:
            for i, pgn in enumerate(pgns):
                f.write(pgn.strip() + "\n\n")
        print(f"[+] Extracted PGNs successfully written to: {PGN_OUTPUT_PATH}")
    else:
        print("[-] No PGN games detected in the raw transcript.")
        
    print("--- Sync Complete ---")

if __name__ == "__main__":
    parse_and_sync()
