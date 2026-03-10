-- Migration: 005_robust_username_system.sql
-- Description: Enforce unique display names and handle existing duplicates

-- First, ensure existing display_names are unique by appending random digits to duplicates
DO $$
DECLARE
    r RECORD;
    new_name TEXT;
    counter INT;
BEGIN
    FOR r IN (
        SELECT display_name, array_agg(id) as ids
        FROM profiles
        WHERE display_name IS NOT NULL
        GROUP BY display_name
        HAVING count(*) > 1
    ) LOOP
        counter := 1;
        -- Skip the first one, rename the rest
        FOR i IN 2 .. array_length(r.ids, 1) LOOP
            LOOP
                new_name := r.display_name || floor(random() * 9000 + 1000)::text;
                -- Check if the new name is also taken
                IF NOT EXISTS (SELECT 1 FROM profiles WHERE display_name = new_name) THEN
                    UPDATE profiles SET display_name = new_name WHERE id = r.ids[i];
                    EXIT;
                END IF;
            END LOOP;
        END LOOP;
    END LOOP;
END $$;

-- Now that data is clean, add the UNIQUE constraint
ALTER TABLE profiles ADD CONSTRAINT profiles_display_name_key UNIQUE (display_name);

-- Update the onboarding trigger to automatically handle collisions
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    base_name TEXT;
    final_name TEXT;
BEGIN
    base_name := NEW.raw_user_meta_data->>'display_name';
    
    IF base_name IS NULL OR base_name = '' THEN
        base_name := 'User';
    END IF;

    final_name := base_name;
    
    -- Loop to find a unique name
    WHILE EXISTS (SELECT 1 FROM public.profiles WHERE display_name = final_name) LOOP
        final_name := base_name || floor(random() * 9000 + 1000)::text;
    END LOOP;

    INSERT INTO public.profiles (user_id, display_name)
    VALUES (NEW.id, final_name);
    
    -- Also create initial stats
    INSERT INTO public.user_stats (profile_id)
    SELECT id FROM public.profiles WHERE user_id = NEW.id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
