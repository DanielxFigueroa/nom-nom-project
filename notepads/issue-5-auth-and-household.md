# Issue #5: Authentication & Household-Joining Flow
Link: https://github.com/DanielxFigueroa/nom-nom-project/issues/5

## Objective
Build the complete user authentication experience, including the logic for creating or joining a household.

## Plan

1. **Investigate Current State:**
   - Review `src/lib/supabase.ts` for Supabase client configuration.
   - Look for existing `profiles` and `households` tables in `database.types.ts` or migrations.
   - Check existing React Native screens (in `app` or `src/app`).

2. **Supabase Database Adjustments:**
   - If not already present, create migrations for `households` (id, invite_code, created_at) and `profiles` (id (fk auth.users), household_id, created_at).
   - Ensure an `invite_code` column exists and perhaps a unique constraint.
   - Alternatively, write a Supabase Edge Function or Postgres function to generate unique `invite_code` and handle household joining safely, or just handle it client-side.

3. **Build Authentication UI:**
   - Use Supabase Auth (email/password).
   - Create Sign Up screen.
   - Create Login screen.

4. **Household Flow UI:**
   - Create a post-auth screen: "Create a new household" or "Join existing household".
   - Create logic:
     - **Create:** Insert into `households` with a random 6-digit `invite_code`. Update `profiles` with `household_id`.
     - **Join:** Query `households` for `invite_code`. If found, update `profiles` with `household_id`. If not, show error.

5. **Testing:**
   - Add unit tests for the household logic using Jest.
   - Verify flow manually or via tests.

6. **Deploy:**
   - Create a PR.
