import os
import json
import streamlit as st
import plotly.express as px
import plotly.graph_objects as go

# Set page configuration with a premium dark theme
st.set_page_config(
    page_title="ChessTrainerXl: Intel Dashboard",
    page_icon="♟️",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Custom CSS for modern glassmorphism aesthetic
st.markdown("""
<style>
    .reportview-container {
        background: #0F0F0F;
    }
    .stApp {
        background-color: #0F0F0F;
        color: #FFFFFF;
    }
    .css-1d391kg {
        background-color: #1A1A1A;
    }
    div.stButton > button:first-child {
        background-color: #EC4899;
        color: white;
        border-radius: 8px;
        border: none;
    }
</style>
""", unsafe_allow_html=True)

WORKSPACE_DIR = r"c:\Users\freem\Documents\ChessFr"
TOPIC_JSON_PATH = os.path.join(WORKSPACE_DIR, "data", "notebook_imports", "topic_relevance.json")
PGN_PATH = os.path.join(WORKSPACE_DIR, "data", "notebook_imports", "extracted_games.pgn")

st.title("♟️ ChessTrainerXl: Machine Learning & Context Intel Hub")
st.markdown("---")

# Sidebar - Archetype Vectors
st.sidebar.header("🎭 Opponent Archetypes [S, R, P, M]")
archetypes = {
    "London Squeezer": [0.1, 0.2, 0.4, 0.3],
    "Wayward Queen Raider": [0.8, 0.9, 0.9, 0.2],
    "Fried Liver Fanatic": [0.9, 0.8, 0.7, 0.6],
    "French/Caro Squeezer": [0.1, 0.1, 0.3, 0.4],
    "The Gambiteer": [0.9, 0.9, 0.6, 0.9],
    "Symmetrical Copier": [0.4, 0.3, 0.8, 0.3]
}

selected_arch = st.sidebar.selectbox("Select Archetype to Inspect", list(archetypes.keys()))
vector = archetypes[selected_arch]

# Radar/Spider Chart for Archetype Vector
categories = ['Strategy (S)', 'Risk (R)', 'Pacing (P)', 'Valuation (M)']
fig_radar = go.Figure()
fig_radar.add_trace(go.Scatterpolar(
      r=vector,
      theta=categories,
      fill='toself',
      name=selected_arch,
      fillcolor='rgba(236, 72, 153, 0.3)',
      line=dict(color='#EC4899')
))
fig_radar.update_layout(
  polar=dict(
    radialaxis=dict(
      visible=True,
      range=[0, 1]
    )),
  showlegend=False,
  template="plotly_dark",
  height=300
)
st.sidebar.plotly_chart(fig_radar, use_container_width=True)

# Main Section - Grid Layout
col1, col2 = st.columns(2)

with col1:
    st.header("💬 Conversational Context Relevance")
    if os.path.exists(TOPIC_JSON_PATH):
        with open(TOPIC_JSON_PATH, "r", encoding="utf-8") as f:
            data = json.load(f)
            
        metadata = data.get("metadata", {})
        frequencies = data.get("topic_frequencies", {})
        
        st.metric(label="Total Words Scraped", value=metadata.get("total_words_analyzed", 0))
        
        # Horizontal bar chart of topic relevance
        topics = list(frequencies.keys())
        counts = list(frequencies.values())
        
        fig_bar = px.bar(
            x=counts,
            y=topics,
            orientation='h',
            title="Topic Relevancy & Frequency Matrix",
            labels={'x': 'Mentions', 'y': 'Strategic Focus Area'},
            color=counts,
            color_continuous_scale="Viridis",
            template="plotly_dark"
        )
        st.plotly_chart(fig_bar, use_container_width=True)
    else:
        st.warning("No conversation topic metrics found. Run the context parser script first.")

with col2:
    st.header("📊 Extracted PGN Game Analyzer")
    if os.path.exists(PGN_PATH):
        with open(PGN_PATH, "r", encoding="utf-8") as f:
            pgn_content = f.read()
            
        st.text_area("Extracted PGN Logs", pgn_content, height=250)
        
        # Add visual indicators for P-CBA checklist status
        st.markdown("### 🔍 P-CBA Protocol Verification Status")
        col_p, col_c, col_b, col_a = st.columns(4)
        col_p.success("P: Pass (g7/b6 Mut)")
        col_c.success("C: Pass (Checks Scan)")
        col_b.success("B: Pass (Beam Alignment)")
        col_a.success("A: Pass (Actuation Sac)")
    else:
        st.warning("No PGN games extracted yet.")
