# Issue #25: Structured Ingredient Entry — Qty/Unit dropdowns + Metric/Imperial toggle

Link to issue: https://github.com/DanielxFigueroa/nom-nom-project/issues/25

## Summary
Replace free-text `Qty`/`Unit` fields in the add/edit ingredients step of `RecipeFormView` with:
- Metric/Imperial toggle defaulting based on user region (`Locale.current`).
- Qty dropdown picker (1-10 + common fractions `¼, ⅓, ½, ⅔, ¾, 1½, 2½`).
- Unit dropdown picker whose options depend on the Metric/Imperial toggle (`RecipeUnit.options(for: measurementSystem)`).

## Implementation Plan

### Task 1: Supabase Database Migration
Create `supabase/migrations/20260802000000_add_measurement_system_to_recipes.sql` to add `measurement_system` column to `recipes` table with default `'imperial'`.

### Task 2: Core Domain Types
- Create `nom-nom-app/NomNom/Core/MeasurementUnits.swift`:
  - `MeasurementSystem` enum (`metric`, `imperial`).
  - `RecipeUnit` enum with unit cases and `options(for:)` method.
  - `QtyOption` struct for 1-10 + fractions.
- Create `nom-nom-app/NomNom/Core/RegionDefaults.swift`:
  - `measurementSystem()` returning `.imperial` if region is "US" / `.us`, else `.metric`.

### Task 3: Data Model & Repository Updates
- `Models/Recipe.swift`: add `measurementSystem: MeasurementSystem` with coding key `measurement_system` and backward-compatible decoding.
- `RecipesRepository.swift`: update `RecipeInput`, `RecipeInsert`, `RecipeUpdate` to include `measurement_system`.

### Task 4: Form Model & UI Updates
- `RecipeFormModel.swift`:
  - Add `measurementSystem` (defaults from `RegionDefaults.measurementSystem()` on create, from `recipe.measurementSystem` on edit).
  - Update `IngredientDraft` with `quantityValue: Double?` and fraction handling.
  - Replace `ingQty` and `ingUnit` strings with `ingQtyOption: QtyOption?` and `ingUnit: RecipeUnit?`.
  - Update `addIngredient()`, `buildPayload()`, and `goNext()` validation.
- `RecipeFormView.swift`:
  - Step 2 UI: add segmented picker for `MeasurementSystem` (`Imperial` vs `Metric`).
  - Replace text fields for Qty and Unit with `Picker` menus.

### Task 5: Build Verification
- Run `xcodegen generate` and `xcodebuild` gate to verify clean `** BUILD SUCCEEDED **`.
