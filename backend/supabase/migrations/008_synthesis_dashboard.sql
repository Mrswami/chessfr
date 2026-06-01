-- ============================================
-- SYNTHESIS MUTATIONS TABLE
-- Stores Val.exe crossover terminology anomalies
-- ============================================

CREATE TABLE IF NOT EXISTS synthesis_mutations (
    anomaly_id TEXT PRIMARY KEY,
    profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    agent_target TEXT,
    map_name TEXT,
    trigger_condition TEXT,
    behavioral_heuristic TEXT,
    spatial_movement_target TEXT,
    blackjack_rule_of_thumb TEXT,
    manual_grade TEXT,
    manual_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE synthesis_mutations ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view own mutations"
    ON synthesis_mutations FOR SELECT
    USING (profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()));

CREATE POLICY "Users can insert own mutations"
    ON synthesis_mutations FOR INSERT
    WITH CHECK (profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()));

CREATE POLICY "Users can update own mutations"
    ON synthesis_mutations FOR UPDATE
    USING (profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()));

CREATE POLICY "Users can delete own mutations"
    ON synthesis_mutations FOR DELETE
    USING (profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()));

-- Indexes
CREATE INDEX IF NOT EXISTS idx_synthesis_mutations_profile_id ON synthesis_mutations(profile_id);
CREATE INDEX IF NOT EXISTS idx_synthesis_mutations_map_name ON synthesis_mutations(map_name);
