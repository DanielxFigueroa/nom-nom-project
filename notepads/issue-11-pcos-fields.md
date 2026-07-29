# Issue 11 Plan: Schema: Add PCOS Nutritional Fields

Link: https://github.com/DanielxFigueroa/nom-nom-project/issues/11

## Objective
Extend the `recipes` table to include specialized fields for PCOS nutritional tracking (`insulin_index_notes` and `meal_timing_suggestions`), integrate them into the Recipe CRUD Form, display them on the Interactive Recipe Detail Modal, and add comprehensive unit tests.

## Plan

### Task 1: Supabase Migration
- Create migration file `recipe-app/supabase/migrations/20260728000000_add_pcos_nutritional_fields_to_recipes.sql`.
- Add SQL ALTER TABLE query:
  ```sql
  ALTER TABLE recipes 
  ADD COLUMN IF NOT EXISTS insulin_index_notes TEXT,
  ADD COLUMN IF NOT EXISTS meal_timing_suggestions TEXT;
  ```

### Task 2: Update Types
- Update `Recipe` interface in `recipe-app/src/types/recipe.ts`:
  ```ts
  export interface Recipe {
    id: string;
    title: string;
    image_url: string;
    description?: string;
    instructions?: string;
    household_id: string;
    is_favorite?: boolean;
    insulin_index_notes?: string;
    meal_timing_suggestions?: string;
    created_at?: string;
  }
  ```

### Task 3: Recipe CRUD Form & Screens Integration
- Update `RecipeForm.tsx`:
  - Add state variables `insulinIndexNotes` and `mealTimingSuggestions` initialized from `initialData`.
  - Add text inputs in Step 1 (Details) under a "PCOS Nutritional Tracking (Optional)" section.
  - Update `onSubmit` signature and call parameters to include `insulin_index_notes` and `meal_timing_suggestions`.
- Update `add-recipe.tsx`:
  - Update `handleSubmit` to insert `insulin_index_notes` and `meal_timing_suggestions` into Supabase `recipes`.
- Update `edit-recipe.tsx`:
  - Update `handleUpdate` to update `insulin_index_notes` and `meal_timing_suggestions` in Supabase `recipes`.

### Task 4: Interactive Recipe Detail Modal
- Update `modal.tsx`:
  - Render a "PCOS Guidance" section showing `insulin_index_notes` and `meal_timing_suggestions` if either field is present.

### Task 5: Testing
- Create unit test `recipe-app/components/__tests__/PCOSFields.test.tsx` verifying:
  - Form input and submission with PCOS fields.
  - Recipe Detail Modal displaying PCOS fields when populated and hiding them when empty.
- Run full test suite with `npm test`.

### Task 6: Branch, Commit & Pull Request
- Create branch `issue-11-pcos-fields`.
- Commit changes with prefix `[AGY:Gemini-3.6-Flash]`.
- Open PR using `gh pr create`.
