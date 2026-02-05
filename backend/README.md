# Backend (Supabase)

This folder is reserved for Supabase configuration, SQL migrations,
and edge functions.

## First-Time Setup (Local)
1. Install the Supabase CLI.
2. Run `supabase init` inside this `backend` folder.
3. Start local stack with `supabase start`.
4. Add migrations in `supabase/migrations`.

## Production
Create a Supabase project and link it:
- `supabase link --project-ref <ref>`
- `supabase db push`
