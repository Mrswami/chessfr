-- Migration: 007_profiles_role.sql
-- Description: Adds a role column to the profiles table, updates the signup sync trigger,
--              and sets up RLS policies to allow Admins to update user roles.

-- 1. Add role column to profiles
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'free' CHECK (role IN ('free', 'premium', 'admin'));

COMMENT ON COLUMN profiles.role IS 'User permission role: free, premium, or admin';

-- 2. Update existing rows to have default values (if null)
UPDATE profiles 
SET role = 'free' 
WHERE role IS NULL;

-- 3. Redefine handle_new_user function to sync metadata role on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (user_id, display_name, role)
    VALUES (
        NEW.id, 
        NEW.raw_user_meta_data->>'display_name',
        COALESCE(NEW.raw_user_meta_data->>'role', 'free')
    );
    
    -- Also create initial stats
    INSERT INTO public.user_stats (profile_id)
    SELECT id FROM public.profiles WHERE user_id = NEW.id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Update Row Level Security (RLS) policies on profiles
-- Drop old update policy if it exists
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;

-- Create new update policy allowing users to update their own profile OR Admins to update any profile
CREATE POLICY "Users can update own profile, Admins can update any profile"
    ON profiles FOR UPDATE
    USING (
        auth.uid() = user_id 
        OR (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
    );
