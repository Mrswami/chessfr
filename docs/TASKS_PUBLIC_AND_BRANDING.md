# Task: Repository Transition & Branding Refresh

## Objective
Finalize the transition of `ChessPersonalTrainer` to the `THEAMATEURSWAMI ORG` organization, audit the codebase for public safety, and refresh the visual branding (Logo).

## Status
- **Repo Transition**: Ownership transferred (User confirmed).
- **Public Visibility**: **PENDING** (Blocked by hardcoded secrets).
- **Branding**: "Santa AI" logo exists; "Eerie Magnus" pivot proposed.

## Tasks
1. [ ] **Security Audit & Secret Scrubbing**
   - [ ] Move Supabase URL/AnonKey from `main.dart` to `--dart-define` or `.env`.
   - [ ] Check for any committed Firebase config or private keys.
   - [ ] Update `.gitignore` to ensure no sensitive files are tracked.
2. [ ] **Branding Refresh**
   - [ ] Generate "Eerie Magnus" logo variant based on the latest vision.
   - [ ] Update `docs/LOGO_DESIGN.md` to reflect the chosen aesthetic.
   - [ ] (Optional) Update app splash screen/icon.
3. [ ] **Organization Alignment**
   - [ ] Update `pubspec.yaml` description/author if needed.
   - [ ] Review `README.md` for professional presentation under the new ORG.

## Proposed Course of Action
I will start by generating the "Eerie Magnus" logo to give you a comparison with the current Santa version. Then, I'll provide a pull request/edit to move your secrets so you can safely make the repo public.
