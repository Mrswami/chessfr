-- ChessPersonalTrainer Initial Schema
-- Run this in Supabase Dashboard > SQL Editor

-- Enable UUID extension (usually already enabled)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- PROFILES TABLE
-- Stores user's coaching profile and cognitive weights
-- ============================================
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
    display_name TEXT,
    cognitive_profile JSONB DEFAULT '{
        "connectivity_weight": 0.5,
        "response_weight": 0.3,
        "influence_weight": 0.2,
        "engine_trust": 0.5
    }'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- POSITIONS TABLE
-- Stores chess positions (FEN strings)
-- ============================================
CREATE TABLE IF NOT EXISTS positions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    fen TEXT NOT NULL UNIQUE,
    side_to_move TEXT CHECK (side_to_move IN ('w', 'b')),
    tags TEXT[] DEFAULT '{}',
    difficulty INTEGER CHECK (difficulty >= 1 AND difficulty <= 10),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- MOVE_RECOMMENDATIONS TABLE
-- Engine + design metrics for position/profile combos
-- ============================================
CREATE TABLE IF NOT EXISTS move_recommendations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    position_id UUID REFERENCES positions(id) ON DELETE CASCADE NOT NULL,
    profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    engine_top3 JSONB NOT NULL, -- array of { move, eval }
    design_metrics JSONB NOT NULL, -- { is_bridge, island_count, connectivity_gain }
    delta_v NUMERIC(6,4), -- evaluation loss accepted
    recommendation_logic TEXT,
    ranked_moves JSONB, -- final ordered list
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- TRAINING_SESSIONS TABLE
-- Captures user responses and progress
-- ============================================
CREATE TABLE IF NOT EXISTS training_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    position_id UUID REFERENCES positions(id) ON DELETE CASCADE NOT NULL,
    chosen_move TEXT NOT NULL,
    response_latency_ms INTEGER,
    outcome TEXT CHECK (outcome IN ('correct', 'incorrect', 'timeout', 'skipped')),
    feedback_shown BOOLEAN DEFAULT FALSE,
    xp_earned INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- USER_STATS TABLE
-- Aggregated stats for gamification
-- ============================================
CREATE TABLE IF NOT EXISTS user_stats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL UNIQUE,
    total_xp INTEGER DEFAULT 0,
    current_streak INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    positions_trained INTEGER DEFAULT 0,
    last_training_date DATE,
    level INTEGER DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- Users can only access their own data
-- ============================================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE move_recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE training_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_stats ENABLE ROW LEVEL SECURITY;

-- Profiles: users can only see/edit their own profile
CREATE POLICY "Users can view own profile"
    ON profiles FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own profile"
    ON profiles FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own profile"
    ON profiles FOR UPDATE
    USING (auth.uid() = user_id);

-- Positions: everyone can read (public puzzles)
ALTER TABLE positions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Positions are viewable by everyone"
    ON positions FOR SELECT
    USING (true);

-- Move recommendations: users can see recommendations for their profile
CREATE POLICY "Users can view own recommendations"
    ON move_recommendations FOR SELECT
    USING (
        profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())
        OR profile_id IS NULL -- generic recommendations
    );

-- Training sessions: users can only see/create their own
CREATE POLICY "Users can view own training sessions"
    ON training_sessions FOR SELECT
    USING (profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()));

CREATE POLICY "Users can insert own training sessions"
    ON training_sessions FOR INSERT
    WITH CHECK (profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()));

-- User stats: users can only see/edit their own
CREATE POLICY "Users can view own stats"
    ON user_stats FOR SELECT
    USING (profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()));

CREATE POLICY "Users can update own stats"
    ON user_stats FOR UPDATE
    USING (profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()));

-- ============================================
-- FUNCTIONS
-- Auto-create profile and stats on user signup
-- ============================================

-- Function to create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (user_id, display_name)
    VALUES (NEW.id, NEW.raw_user_meta_data->>'display_name');
    
    -- Also create initial stats
    INSERT INTO public.user_stats (profile_id)
    SELECT id FROM public.profiles WHERE user_id = NEW.id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to auto-create profile
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- INDEXES
-- For query performance
-- ============================================
CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_positions_fen ON positions(fen);
CREATE INDEX IF NOT EXISTS idx_training_sessions_profile ON training_sessions(profile_id);
CREATE INDEX IF NOT EXISTS idx_training_sessions_created ON training_sessions(created_at);
CREATE INDEX IF NOT EXISTS idx_move_recommendations_position ON move_recommendations(position_id);

-- ============================================
-- SEED DATA
-- Sample positions to get started
-- ============================================
INSERT INTO positions (fen, side_to_move, tags, difficulty) VALUES
    ('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1', 'w', ARRAY['opening', 'starter'], 1),
    ('r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4', 'w', ARRAY['opening', 'italian'], 3),
    ('r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 2 3', 'w', ARRAY['opening', 'knight'], 2),
    ('r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4', 'w', ARRAY['opening', 'giuoco_piano'], 4),
    ('rnbqkb1r/pp1ppppp/5n2/2p5/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq c6 0 3', 'w', ARRAY['opening', 'sicilian'], 5)
ON CONFLICT (fen) DO NOTHING;
