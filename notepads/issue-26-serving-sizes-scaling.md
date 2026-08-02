# Issue #26: Serving sizes & ingredient scaling

Link to issue: https://github.com/DanielxFigueroa/nom-nom-project/issues/26

## Summary
Store a **base serving count** per recipe; on the detail screen let the user pick a desired serving count and scale every ingredient amount proportionally.

## Implementation Plan

### Task 1: Supabase Database Migration
- Create `supabase/migrations/20260802120000_add_servings_and_numeric_qty.sql` adding:
  - `servings integer not null default 4` to `recipes`.
  - `quantity_value numeric` to `ingredients`.
- Apply migration locally / to Supabase and reload schema.

### Task 2: Core Formatter — `NomNom/Core/FractionFormatter.swift`
- Create `FractionFormatter.swift` to render numbers as clean fractions (`1.5 -> "1 ½"`, `0.25 -> "¼"`), mixed numbers, or rounded decimals.

### Task 3: Data Model & Repository Updates
- `Models/Recipe.swift`: add `servings: Int` (CodingKey `servings`, default 4).
- `Models/Ingredient.swift`: add `quantityValue: Double?` (CodingKey `quantity_value`).
- `RecipesRepository.swift`:
  - `RecipeInput`/`RecipeInsert`/`RecipeUpdate` gain `servings`.
  - `IngredientInput`/`IngredientInsert` gain `quantityValue`/`quantity_value`.
  - Update `createRecipe`, `updateRecipe`, `insertIngredients`.

### Task 4: Form Model & UI Updates
- `RecipeFormModel.swift`:
  - Add `servings: Int = 4` (init from `recipe.servings` on edit).
  - Pass `servings` into `RecipeInput` in `buildPayload()`.
  - Pass `quantityValue` into `IngredientInput` in `buildPayload()`.
- `RecipeFormView.swift`:
  - Step 1 (Details): Add a **Servings** stepper (min 1) bound to `model.servings`.

### Task 5: Recipe Detail Model & UI Updates
- `RecipeDetailModel.swift`:
  - `desiredServings: Int` (init to `recipe.servings`).
  - `scaleFactor: Double` computed as `Double(desiredServings) / Double(max(recipe.servings, 1))`.
  - Helper function `formattedQuantity(for ingredient: Ingredient) -> String?` returning scaled fraction string if `quantityValue != nil`, else raw `quantity`.
  - Property `hasLegacyUnscalableIngredients: Bool`.
- `RecipeDetailView.swift`:
  - Add Servings stepper header above ingredient list ("Serves 6 · base 4", reset button when modified).
  - Update ingredient rows to display scaled quantities.
  - Display "scaling unavailable" note for legacy ingredients if present.

### Task 6: Build Gate & Verification
- Run `xcodegen generate` and `xcodebuild` gate to verify clean `** BUILD SUCCEEDED **`.
