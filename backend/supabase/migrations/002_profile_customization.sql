-- Add profile customization columns
-- Migration: 002_profile_customization.sql
-- Description: Adds avatar customization and engine mode preferences

-- Add new columns to profiles table
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS engine_mode TEXT DEFAULT 'stockfish' CHECK (engine_mode IN ('stockfish', 'dankfish')),
ADD COLUMN IF NOT EXISTS avatar_variant TEXT DEFAULT 'classic' CHECK (avatar_variant IN ('classic', 'jolly', 'cool', 'sleepy')),
ADD COLUMN IF NOT EXISTS avatar_background TEXT DEFAULT 'dark' CHECK (avatar_background IN ('dark', 'blue', 'green', 'purple'));

-- Add comment for documentation
COMMENT ON COLUMN profiles.engine_mode IS 'User preference for engine analysis: stockfish (pure) or dankfish (personalized)';
COMMENT ON COLUMN profiles.avatar_variant IS 'Selected Santa avatar variant for profile display';
COMMENT ON COLUMN profiles.avatar_background IS 'Background color theme for profile card';

-- Update existing rows to have default values
UPDATE profiles 
SET 
  engine_mode = 'stockfish',
  avatar_variant = 'classic',
  avatar_background = 'dark'
WHERE engine_mode IS NULL;
