# Issue #38: DB — Add name column to households table

Link to issue: https://github.com/DanielxFigueroa/nom-nom-project/issues/38

## Objective
Add an optional `name` column to the `households` table so that joined households can be labeled meaningfully in the UI (e.g. household filter pill bar and Households list view).

## Plan

1. **Create Supabase Migration**
   File: `supabase/migrations/20260817010000_add_name_to_households.sql`
   - Add column `name text` to `public.households` if not exists:
     ```sql
     ALTER TABLE public.households ADD COLUMN IF NOT EXISTS name text;
     ```
   - Reload PostgREST schema cache:
     ```sql
     notify pgrst, 'reload schema';
     ```

2. **Update Swift Models and Auth Code**
   - `NomNom/Models/Household.swift`:
     Add optional `var name: String?` property and `case name` to `CodingKeys`.
   - `NomNom/Auth/HouseholdRepository.swift`:
     Update `createHousehold(name: String? = nil)` to accept optional `name` parameter and include it in `insert` payload when provided.
   - `NomNom/Auth/HouseholdSetupModel.swift`:
     Add `var householdName: String = ""` property and forward it in `createHousehold(auth:)`.
   - `NomNom/Auth/HouseholdSetupView.swift`:
     Add a TextField for Household Name (optional) in the "Create a New Household" section.

3. **Verify iOS Build**
   - Run `xcodegen generate` and `xcodebuild` for iOS Simulator.
   - Ensure build succeeds (`** BUILD SUCCEEDED **`).

4. **Commit & Push**
   - Commit changes with message `[AGY:Gemini-3.6-Flash] M4: DB — Add name column to households table (Closes #38)`.
   - Push branch `issue-38-add-name-to-households`.
   - Create PR using `gh pr create`.
