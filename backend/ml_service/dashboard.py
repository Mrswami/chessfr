import streamlit as st
import plotly.graph_objects as go
import chess
import chess.pgn
import chess.svg
import numpy as np
import os
import sys

# Ensure the root of ml_service is on the python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

import config
from data.dataset_loader import DatasetLoader, PGNDataset
from models.registry import ModelRegistry
from pipeline.bias_tracker import BiasTracker
from data.pattern_engine import PatternEngine

# 1. Page Configuration
st.set_page_config(
    layout="wide",
    page_title="AmateurSwami Intelligence Dashboard",
    page_icon="♟️",
)

# Premium Custom CSS for Dark Glassmorphism Theme
st.markdown("""
<style>
    /* Main background */
    .stApp {
        background-color: #0d1117;
        color: #c9d1d9;
        font-family: 'Outfit', 'Inter', sans-serif;
    }
    
    /* Headers */
    h1, h2, h3 {
        color: #ffffff !important;
        font-weight: 700;
        letter-spacing: -0.5px;
    }
    
    /* Cards styling */
    .metric-card {
        background: rgba(22, 27, 34, 0.6);
        border: 1px solid rgba(48, 54, 61, 0.8);
        border-radius: 12px;
        padding: 20px;
        margin-bottom: 15px;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
    }
    
    .metric-card h4 {
        margin-top: 0;
        color: #58a6ff;
    }
    
    /* Neon border utilities */
    .neon-border-emerald {
        border-left: 5px solid #39d353 !important;
    }
    .neon-border-amber {
        border-left: 5px solid #ecb22e !important;
    }
    .neon-border-crimson {
        border-left: 5px solid #f85149 !important;
    }
    
    /* Sidebar styling */
    .css-1633q7t {
        background-color: #161b22;
    }
</style>
""", unsafe_allow_html=True)

# Header Section
st.title("♟️ ChessTrainerXl: Machine Learning Prediction Warehouse")
st.markdown("### Interactive Cognitive Analysis & Personal Bias Tracker")
st.markdown("---")

# Lazy load ONNX model and dataset helpers
@st.cache_resource
def get_registry():
    onnx_path = os.path.join(config.MODEL_DIR, "dankfish_baseline.onnx")
    if not os.path.exists(onnx_path):
        from pipeline import export_onnx
        export_onnx.main()
    return ModelRegistry()

@st.cache_resource
def get_loader():
    return DatasetLoader()

@st.cache_resource
def get_pattern_engine():
    return PatternEngine()

# Initialize services
registry = get_registry()
loader = get_loader()
pattern_engine = get_pattern_engine()

# Tabs
tab1, tab2, tab3 = st.tabs([
    "🎯 Psychological Fingerprint", 
    "👁️ Magic Eyes (Model Visualizer)", 
    "⚙️ Dataset Manager & Trainer"
])

# =====================================================================
# TAB 1: PSYCHOLOGICAL FINGERPRINT
# =====================================================================
with tab1:
    st.header("🎯 The AmateurSwami Psychological Fingerprint")
    st.markdown("This radar chart maps your personal chess shortcomings compared to Lichess Masters. A higher score represents a stronger bias/flaw.")

    col1, col2 = st.columns([1, 1])

    # Load games and run bias tracker
    pgn_path = config.PERSONAL_GAMES_PATH
    if not os.path.exists(pgn_path):
        pgn_path = os.path.join(config.DATA_DIR, "sample_games.pgn")
        st.info(f"Personal PGN not found. Rendering using sample database: {pgn_path}")

    # Read games from PGN
    games = []
    try:
        with open(pgn_path, "r", encoding="utf-8") as f:
            for _ in range(50):  # Load up to 50 games for fast load
                g = chess.pgn.read_game(f)
                if g is None:
                    break
                games.append(g)
    except Exception as e:
        st.error(f"Error loading PGN: {str(e)}")

    # Calculate biases
    tracker = BiasTracker(player_name="AmateurSwami")
    biases = tracker.analyze_history(games)

    # Plotly Radar Chart
    categories = [
        "Premature Queen", 
        "Castling Delay", 
        "Pawn Phobia", 
        "Luft Neglect", 
        "Exchange Panic", 
        "King Hunt"
    ]
    user_values = [
        biases["premature_queen"],
        biases["castling_delay"],
        biases["pawn_phobia"],
        biases["luft_neglect"],
        biases["exchange_panic"],
        biases["king_hunt"]
    ]
    # Standard baseline values representing disciplined masters
    master_values = [0.10, 0.12, 0.15, 0.08, 0.20, 0.10]

    fig = go.Figure()
    
    # Add User trace
    fig.add_trace(go.Scatterpolar(
        r=user_values,
        theta=categories,
        fill='toself',
        name='AmateurSwami (You)',
        fillcolor='rgba(88, 166, 255, 0.3)',
        line=dict(color='#58a6ff', width=3)
    ))
    
    # Add Masters trace
    fig.add_trace(go.Scatterpolar(
        r=master_values,
        theta=categories,
        fill='toself',
        name='Lichess Masters',
        fillcolor='rgba(57, 211, 83, 0.1)',
        line=dict(color='#39d353', width=2, dash='dash')
    ))

    fig.update_layout(
        polar=dict(
            radialaxis=dict(
                visible=True,
                range=[0, 1]
            ),
            bgcolor='rgba(13, 17, 23, 1.0)'
        ),
        paper_bgcolor='rgba(13, 17, 23, 1.0)',
        plot_bgcolor='rgba(13, 17, 23, 1.0)',
        font=dict(color='#c9d1d9'),
        showlegend=True,
        margin=dict(t=30, b=30, l=30, r=30)
    )

    with col1:
        st.plotly_chart(fig, use_container_width=True)

    with col2:
        st.subheader("📚 Deficit Assessment & Remedies")
        
        # Display feedback for each bias
        metrics = [
            ("Premature Queen Activation", biases["premature_queen"], "Avoid moving the Queen before developing Knights and Bishops. Every move she gets attacked is a wasted turn.", "neon-border-amber"),
            ("King Safety Neglect", biases["castling_delay"], "Castling after move 12 exposes your king. Prioritize early castling to tuck the king behind protected pawns.", "neon-border-crimson"),
            ("Pawn Structure Phobia", biases["pawn_phobia"], "Don't avoid winning exchanges solely because they double your pawns. A doubled pawn is only weak if the opponent can attack it.", "neon-border-emerald"),
            ("Luft Neglect", biases["luft_neglect"], "Create an escape square (h3/h6) during quiet middlegame transitions to prevent sudden back-rank mating traps.", "neon-border-amber"),
            ("Exchange Panic", biases["exchange_panic"], "Panicking and trading pieces immediately when attacked resolves board tension. Maintain the tension and search for counterattacks.", "neon-border-crimson"),
            ("King Hunt Bias", biases["king_hunt"], "Avoid chasing the enemy king with speculative checks while hanging your pieces elsewhere. Focus on space and coordination.", "neon-border-emerald")
        ]
        
        for title, val, remedy, border in metrics:
            st.markdown(f"""
            <div class="metric-card {border}">
                <h4>{title} : {val * 100:.1f}%</h4>
                <p><strong>Remedy:</strong> {remedy}</p>
            </div>
            """, unsafe_allow_html=True)


# =====================================================================
# TAB 2: MAGIC EYES (MODEL VISUALIZER)
# =====================================================================
with tab2:
    st.header("👁️ Magic Eyes Board Visualizer")
    st.markdown("Input any FEN string and see exactly where the trained neural network model is focusing its attention.")

    col_board, col_preds = st.columns([1, 1])

    with col_preds:
        fen_input = st.text_input(
            "Enter FEN string:",
            value=chess.STARTING_FEN
        )
        archetype_selection = st.selectbox(
            "Select Opponent Archetype Profile:",
            ["London Squeezer", "Wayward Queen Raider", "Fried Liver Fanatic", "French/Caro Squeezer", "Gambiteer", "Symmetrical Copier"]
        )

        try:
            board = chess.Board(fen_input)
            valid_fen = True
        except ValueError:
            st.error("Invalid FEN string format.")
            valid_fen = False

    if valid_fen:
        # Run inference
        tensor = loader.fen_to_hybrid_tensor(board)
        policy_logits, attn_probs = registry.predict(tensor)

        # Softmax over legal moves
        legal_moves = list(board.legal_moves)
        if legal_moves:
            legal_logits = np.array([policy_logits[DatasetLoader.encode_move(m)] for m in legal_moves])
            shifted_logits = legal_logits - np.max(legal_logits)
            exp_logits = np.exp(shifted_logits)
            normalized_probs = exp_logits / np.sum(exp_logits)
            
            sorted_indices = np.argsort(normalized_probs)[::-1]
        else:
            normalized_probs = []

        # Color the chessboard squares dynamically to show model focus
        fill_dict = {}
        
        # 1. Overlay attention heatmap values (Sigmoids in translucent Crimson)
        for sq in range(64):
            val = float(attn_probs[sq])
            if val > 0.4:
                # Map rank/file to standard 0-63 square numbering index
                fill_dict[sq] = f"rgba(248, 81, 73, {val * 0.4})"

        # 2. Highlight top move destinations in translucent Emerald
        if legal_moves:
            top_move = legal_moves[sorted_indices[0]]
            fill_dict[top_move.to_square] = "rgba(57, 211, 83, 0.6)"
            if len(sorted_indices) > 1:
                second_move = legal_moves[sorted_indices[1]]
                fill_dict[second_move.to_square] = "rgba(88, 166, 255, 0.4)"

        # Render Board SVG
        board_svg = chess.svg.board(board=board, fill=fill_dict, size=400)

        with col_board:
            st.components.v1.html(board_svg, height=410)

        with col_preds:
            st.subheader("Model Predictions (Top Moves)")
            if legal_moves:
                for i in range(min(5, len(legal_moves))):
                    orig_idx = sorted_indices[i]
                    move = legal_moves[orig_idx]
                    prob = float(normalized_probs[orig_idx])
                    
                    dest_sq = move.to_square
                    attn_val = float(attn_probs[dest_sq])
                    
                    # Highlight colors matching dashboard visuals
                    if i == 0:
                        badge = "🟢 (Top Prediction)"
                    elif attn_val > 0.5:
                        badge = "🔵 (Tunnel Focus)"
                    else:
                        badge = "⚪"
                        
                    st.write(f"**{i+1}. {board.san(move)}** ({move.uci()}) — Probability: **{prob*100:.1f}%** | Attention: **{attn_val:.2f}** {badge}")
            else:
                st.write("No legal moves available (Checkmate/Stalemate).")


# =====================================================================
# TAB 3: DATASET MANAGER & TRAINER
# =====================================================================
with tab3:
    st.header("⚙️ Dataset Manager & Live Training Panel")
    st.markdown("Adjust ratio weights, upload new PGN files, and trigger the supervised training pipeline.")

    col_setup, col_run = st.columns([1, 1])

    with col_setup:
        st.subheader("Data Partitioning")
        ratio = st.slider(
            "Lichess to Personal Games Ratio:",
            min_value=0.0,
            max_value=1.0,
            value=config.LICHESS_RATIO,
            step=0.05,
            help="Higher ratio means the model trains more on general Lichess games. Lower ratio forces it to learn from your games."
        )
        
        uploaded_personal = st.file_uploader("Upload Personal PGN (AmateurSwami games):", type=["pgn"])
        uploaded_lichess = st.file_uploader("Upload Lichess PGN (General database):", type=["pgn"])

        if uploaded_personal:
            # Save uploaded PGN to config path
            with open(config.PERSONAL_GAMES_PATH, "wb") as f:
                f.write(uploaded_personal.getbuffer())
            st.success(f"Saved personal games to: {config.PERSONAL_GAMES_PATH}")
            
        if uploaded_lichess:
            with open(config.LICHESS_GAMES_PATH, "wb") as f:
                f.write(uploaded_lichess.getbuffer())
            st.success(f"Saved Lichess games to: {config.LICHESS_GAMES_PATH}")

    with col_run:
        st.subheader("Train Model")
        epochs = st.number_input("Epochs:", min_value=1, max_value=50, value=config.EPOCHS)
        batch_size = st.selectbox("Batch Size:", [16, 32, 64, 128], index=2)
        max_pos = st.number_input("Max Positions to load:", min_value=100, max_value=100000, value=1000)

        if st.button("🚀 Start Supervised Training Run"):
            # Set environment variable for LICHESS_RATIO so config parses it
            os.environ["LICHESS_RATIO"] = str(ratio)
            
            with st.spinner("Training neural network... logs are outputting to console."):
                try:
                    # Run training pipeline
                    import subprocess
                    # Trigger python command executing pipeline
                    cmd = [
                        "python", 
                        "pipeline/train_move_predictor.py", 
                        f"--epochs={epochs}",
                        f"--batch_size={batch_size}",
                        f"--ratio={ratio}",
                        f"--max_positions={max_pos}"
                    ]
                    result = subprocess.run(cmd, capture_output=True, text=True)
                    
                    st.text_area("Training Console Output:", value=result.stdout, height=250)
                    
                    if result.returncode == 0:
                        st.success("Model trained successfully! Compiling to ONNX...")
                        # Run export_onnx inline to update the model
                        from pipeline import export_onnx
                        export_onnx.main()
                        # Reload registry session
                        registry.load_model()
                        st.success("ONNX compiled and registry reloaded! Ready for predictions.")
                    else:
                        st.error(f"Training failed with exit code: {result.returncode}")
                        st.text_area("Error details:", value=result.stderr, height=150)
                except Exception as e:
                    st.error(f"Error running pipeline: {str(e)}")
