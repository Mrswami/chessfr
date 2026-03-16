-- Migration: 006_concierge_and_hall_of_fame.sql
-- Description: Adds game_analyses and hall_of_fame tables for Brilliant Tracker,
--              Hall of Fame, and the Concierge recommendation engine.

-- ============================================
-- GAME_ANALYSES TABLE
-- Stores per-game analysis results including brilliant/blunder moves
-- ============================================
CREATE TABLE IF NOT EXISTS game_analyses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    chess_com_url TEXT,                  -- Original Chess.com game URL (for deduplication)
    pgn TEXT NOT NULL,                   -- Full PGN
    user_side TEXT CHECK (user_side IN ('w', 'b')),
    opponent_username TEXT,
    opponent_rating INTEGER,
    time_control TEXT,
    opening_name TEXT,                   -- Parsed from PGN headers (ECO/Opening)
    game_result TEXT CHECK (game_result IN ('win', 'loss', 'draw')),
    -- Aggregated metrics
    total_moves INTEGER DEFAULT 0,
    brilliant_count INTEGER DEFAULT 0,
    excellent_count INTEGER DEFAULT 0,
    good_count INTEGER DEFAULT 0,
    inaccuracy_count INTEGER DEFAULT 0,
    mistake_count INTEGER DEFAULT 0,
    blunder_count INTEGER DEFAULT 0,
    -- JSON arrays of annotated moves
    annotated_moves JSONB DEFAULT '[]'::jsonb,  -- [{moveIndex, fen, san, cpl, classification, evalBefore, evalAfter}]
    brilliant_moves JSONB DEFAULT '[]'::jsonb,  -- subset of annotated_moves where classification='brilliant'
    -- Concierge signals
    weakness_tags TEXT[] DEFAULT '{}',   -- e.g. ['endgame', 'bishop_endgame', 'time_pressure']
    created_at TIMESTAMPTZ DEFAULT NOW(),
    analyzed_at TIMESTAMPTZ DEFAULT NOW()
);

-- Prevent analyzing the same game twice for the same user
CREATE UNIQUE INDEX IF NOT EXISTS idx_game_analyses_url_profile 
    ON game_analyses(profile_id, chess_com_url) 
    WHERE chess_com_url IS NOT NULL;

-- ============================================
-- HALL_OF_FAME TABLE
-- Community-curated brilliant moments
-- ============================================
CREATE TABLE IF NOT EXISTS hall_of_fame (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nominator_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    game_analysis_id UUID REFERENCES game_analyses(id) ON DELETE SET NULL,
    featured_display_name TEXT NOT NULL,  -- may be a pro player name
    fen TEXT NOT NULL,                    -- position before the brilliant move
    move_san TEXT NOT NULL,               -- the brilliant move
    pgn TEXT,                             -- full game for replay
    caption TEXT CHECK (char_length(caption) <= 280),
    upvotes INTEGER DEFAULT 0,
    is_approved BOOLEAN DEFAULT FALSE,    -- admin moderation gate
    is_pinned BOOLEAN DEFAULT FALSE,      -- weekly top 3
    week_number INTEGER,                  -- ISO week for weekly pinnning
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- HALL_OF_FAME UPVOTES TABLE
-- Tracks who upvoted what (prevents double-voting)
-- ============================================
CREATE TABLE IF NOT EXISTS hall_of_fame_upvotes (
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    hof_id UUID REFERENCES hall_of_fame(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (user_id, hof_id)
);

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================
ALTER TABLE game_analyses ENABLE ROW LEVEL SECURITY;
ALTER TABLE hall_of_fame ENABLE ROW LEVEL SECURITY;
ALTER TABLE hall_of_fame_upvotes ENABLE ROW LEVEL SECURITY;

-- game_analyses: users can only read/write their own
CREATE POLICY "Users can view own game analyses"
    ON game_analyses FOR SELECT
    USING (profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()));

CREATE POLICY "Users can insert own game analyses"
    ON game_analyses FOR INSERT
    WITH CHECK (profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()));

CREATE POLICY "Users can update own game analyses"
    ON game_analyses FOR UPDATE
    USING (profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()));

-- hall_of_fame: approved entries are publicly readable
CREATE POLICY "Approved Hall of Fame entries are public"
    ON hall_of_fame FOR SELECT
    USING (is_approved = TRUE);

CREATE POLICY "Users can submit to Hall of Fame"
    ON hall_of_fame FOR INSERT
    WITH CHECK (auth.uid() = nominator_user_id);

-- upvotes: users can insert their own
CREATE POLICY "Users can upvote"
    ON hall_of_fame_upvotes FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their upvotes"
    ON hall_of_fame_upvotes FOR SELECT
    USING (auth.uid() = user_id);

-- ============================================
-- INDEXES
-- ============================================
CREATE INDEX IF NOT EXISTS idx_game_analyses_profile ON game_analyses(profile_id);
CREATE INDEX IF NOT EXISTS idx_game_analyses_created ON game_analyses(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_hall_of_fame_approved ON hall_of_fame(is_approved, upvotes DESC);
CREATE INDEX IF NOT EXISTS idx_hall_of_fame_week ON hall_of_fame(week_number, is_pinned);
