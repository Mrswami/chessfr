-- Enable public reading of training sessions for the Social Hub
-- Migration: 004_community_social_hub.sql

DROP POLICY IF EXISTS "Training sessions are viewable by everyone" ON training_sessions;
CREATE POLICY "Training sessions are viewable by everyone" 
ON training_sessions FOR SELECT 
USING (true);
