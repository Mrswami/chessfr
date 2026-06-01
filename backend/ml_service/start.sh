#!/bin/bash
# Start Streamlit dashboard in the background
streamlit run dashboard.py --server.port 8501 --server.address 0.0.0.0 &

# Start FastAPI application in the foreground
exec uvicorn main:app --host 0.0.0.0 --port 8000
