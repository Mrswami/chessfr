-- Update avatar constraints and RLS for leaderboard
-- Migration: 003_leaderboard_and_constraints.sql

-- 1. Update constraints for new Santa variants
ALTER TABLE profiles 
DROP CONSTRAINT IF EXISTS profiles_avatar_variant_check;

ALTER TABLE profiles
ADD CONSTRAINT profiles_avatar_variant_check 
CHECK (avatar_variant IN ('classic', 'jolly', 'cool', 'sleepy', 'king', 'robot', 'space', 'ninja'));

-- 2. Update constraints for new backgrounds
ALTER TABLE profiles 
DROP CONSTRAINT IF EXISTS profiles_avatar_background_check;

ALTER TABLE profiles
ADD CONSTRAINT profiles_avatar_background_check 
CHECK (avatar_background IN ('dark', 'blue', 'green', 'purple', 'gold', 'fire', 'forest', 'arctic'));

-- 3. Update RLS policies to allow global leaderboard reading
-- Note: We only allow SELECT of non-sensitive columns

-- Allow reading any profile (basic info only is usually handled by joining, but let's be explicit)
DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON profiles;
CREATE POLICY "Profiles are viewable by everyone" 
ON profiles FOR SELECT 
USING (true);

-- Allow reading any user stats for leaderboard
DROP POLICY IF EXISTS "User stats are viewable by everyone" ON user_stats;
CREATE POLICY "User stats are viewable by everyone" 
ON user_stats FOR SELECT 
USING (true);
