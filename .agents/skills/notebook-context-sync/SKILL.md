---
name: notebook-context-sync
description: Ingests, parses, and synchronizes raw text dumps and transcripts from Google LLM Notebooks (like NotebookLM) into structured files in the workspace (docs/, data/) and updates behavioral schemas.
---

# Google LLM Notebook Context Syncing Skill

Use this skill when the user wants to sync transcripts, chess lessons, or database structures exported from Google NotebookLM/Colab.

## 🛠️ Ingestion Pipeline Workflow

1. **Dump File**: Save raw text or markdown transcripts to:
   `c:\Users\freem\Documents\ChessFr\data\notebook_imports\raw_dump.txt`

2. **Parser Execution**: Run the synchronization script:
   `python c:\Users\freem\Documents\ChessFr\.agents\skills\notebook-context-sync\scripts\sync_context.py`

3. **Behavioral Updates**: The script will automatically:
   - Extract raw PGN games and write them to `data/notebook_imports/extracted_games.pgn`.
   - Analyze text for conversational topics (e.g., "P-CBA", "NoSQL", "Red Mist") and update a running JSON file of topic frequencies (`data/notebook_imports/topic_relevance.json`).
   - Extract JSON schemas and update configuration files.
