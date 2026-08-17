# Issue #37: DB — Add household_members join table + multi-household RLS policies

Link to issue: https://github.com/DanielxFigueroa/nom-nom-project/issues/37

## Objective
Introduce a `household_members` join table so users can belong to multiple households simultaneously. Update RLS policies on `recipes`, `ingredients`, `folders`, `tags`, and `recipe_tags` to grant access across all households the user has joined.

## Plan

1. **Create Supabase Migration**
   File: `supabase/migrations/20260817000000_add_household_members.sql`
   - Create `public.household_members` table: `(user_id uuid, household_id uuid, joined_at timestamptz)`.
   - Primary key: `(user_id, household_id)`.
   - Enable RLS on `household_members`.
   - Add RLS policies for `household_members`:
     - Users can select their own memberships (`user_id = auth.uid()`).
     - Users can insert their own memberships (`user_id = auth.uid()`).
   - Backfill existing data: `INSERT INTO public.household_members (user_id, household_id) SELECT id, household_id FROM public.profiles WHERE household_id IS NOT NULL ON CONFLICT DO NOTHING;`.
   - Update RLS policies for `recipes`:
     - Access if `household_id IN (SELECT household_id FROM public.household_members WHERE user_id = auth.uid())`.
   - Update RLS policies for `ingredients`:
     - Access if recipe's `household_id IN (SELECT household_id FROM public.household_members WHERE user_id = auth.uid())`.
   - Update RLS policies for `folders`:
     - Access if `household_id IN (SELECT household_id FROM public.household_members WHERE user_id = auth.uid())`.
   - Update RLS policies for `tags`:
     - Access if `household_id IN (SELECT household_id FROM public.household_members WHERE user_id = auth.uid())`.
   - Update RLS policies for `recipe_tags`:
     - Access if recipe's `household_id IN (SELECT household_id FROM public.household_members WHERE user_id = auth.uid())`.
   - Add schema reload signal `notify pgrst, 'reload schema';`.

2. **Verify iOS App Build**
   - Run `xcodegen generate` and `xcodebuild` for iOS Simulator.
   - Ensure build succeeds (`** BUILD SUCCEEDED **`).

3. **Commit & Push**
   - Commit with reference to `Closes #37`.
   - Push branch `issue-37-household-members`.
   - Create PR using `gh pr create`.
