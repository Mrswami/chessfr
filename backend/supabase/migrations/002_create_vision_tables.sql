-- Migration: 002_create_vision_tables.sql
-- Description: Tables for storing physical board games recorded via Chess Vision (Camera).

-- 1. Table: live_sessions (Stores the active state of a vision session)
create table public.live_sessions (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) not null,
  status text check (status in ('active', 'completed', 'discarded')) default 'active',
  
  -- Chess Data
  fen text not null, -- Current board state
  pgn text,          -- Full move history
  
  -- Metadata
  started_at requests.timestamp default now(),
  updated_at requests.timestamp default now(),
  device_id text     -- Optional: to track which device recorded it
);

-- 2. Security: Enable RLS (Row Level Security)
alter table public.live_sessions enable row level security;

-- 3. Policy: Users can only see/edit their own sessions
create policy "Users can manage their own live sessions"
  on public.live_sessions
  for all -- select, insert, update, delete
  using (auth.uid() = user_id);

-- 4. Realtime: Enable listening to this table (for the "Spectator" view later)
alter publication supabase_realtime add table public.live_sessions;
