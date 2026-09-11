# Issue #76: PCOS Assistant: One-Tap Ingredient Swaps & Recipe Variation Forking

Link to issue: https://github.com/DanielxFigueroa/nom-nom-project/issues/76

## Summary
Allow users to act on PCOS suggestions with one tap: either replace an ingredient in place with serving scaling recalculation, or save the modified recipe as a new distinct "PCOS-Friendly" variation in their household.

Includes confirmation alerts before modifying shared household recipes, undo affordances, and an "Adapted for PCOS" audit badge on recipe cards.

---

## Technical Tasks

### Task 1: Database Migration & Model Updates
- Migration `supabase/migrations/20260911000000_add_is_pcos_adapted_to_recipes.sql`:
  - Add additive column `is_pcos_adapted BOOLEAN NOT NULL DEFAULT FALSE` to `recipes` table.
  - Reload PostgREST schema cache.
- `NomNom/Models/Recipe.swift`:
  - Add `isPCOSAdapted: Bool` (CodingKey `is_pcos_adapted`, default `false`).
- `NomNom/Recipes/RecipesRepository.swift`:
  - Update `RecipeInput`, `RecipeInsert`, `RecipeUpdate` with `isPCOSAdapted`.
  - Include graceful fallback handling if `is_pcos_adapted` is not yet available on remote server.
- `NomNom/Recipes/RecipeFormModel.swift`:
  - Preserve `isPCOSAdapted` when editing in `EditRecipeView`.

### Task 2: Inline Replacement & Recipe Forking in `RecipeDetailModel.swift`
- Add state properties:
  - `appliedSwapIDs: Set<String>`
  - `lastAppliedSwap: (swap: PCOSAnalysisResult.SwapSuggestion, previousIngredients: [Ingredient], previousRecipe: Recipe)?`
  - `swapSuccessMessage: String?`, `swapErrorMessage: String?`, `isApplyingSwap: Bool`
  - `forkSuccessMessage: String?`, `forkErrorMessage: String?`, `isForkingVariation: Bool`
- Implement `applySwap(_ swap: PCOSAnalysisResult.SwapSuggestion)`:
  - Finds matching ingredient using exact and substring matching.
  - Backs up previous state for undo affordance.
  - Updates ingredient `name`, `quantity`, `unit`, and parses `quantityValue`.
  - Recalculates serving scaling automatically via existing `scaleFactor` and `formattedLabel`.
  - Sets `recipe.isPCOSAdapted = true`.
  - Persists changes via `repository.updateRecipe`.
  - Invalidates cache and refreshes PCOS insights.
- Implement `undoSwap()`:
  - Reverts ingredients and recipe to previous backup.
  - Persists reverted state and invalidates cache.
- Implement `forkAsPCOSVariation(householdID: UUID)`:
  - Clones recipe with all suggested swaps applied.
  - Appends `(PCOS-Friendly)` to title if not already present.
  - Ensures reserved PCOS tag exists via `tagsRepository.ensurePCOSTag` and appends it to recipe tags.
  - Sets `isPCOSAdapted = true`.
  - Inserts new recipe row via `repository.createRecipe`.

### Task 3: Swap Actions & Fork Button in `PCOSInsightsCard.swift`
- Add "Apply Swap" button to each swap card:
  - If swap is applied, displays "Applied" badge with checkmark.
  - If not applied, displays "Apply Swap" button.
  - Tapping shows confirmation alert before modifying:
    `"Replace '[original]' with '[suggested]'? This will update the recipe for all members of your household."`
  - Disables button while applying.
- Add "Save as PCOS Variation" button:
  - Positioned at the bottom of the Smart Swaps section.
  - Shows loading indicator while creating variation.
  - Triggers recipe refresh on success.

### Task 4: Audit Badge & Undo Banner in `RecipeCard.swift` and `RecipeDetailView.swift`
- `NomNom/Components/RecipeCard.swift`:
  - Display subtle "Adapted for PCOS" badge with sparkles icon on top-leading corner when `recipe.isPCOSAdapted`.
- `NomNom/Recipes/RecipeDetailView.swift`:
  - Display subtle "Adapted for PCOS" badge near recipe title/tags when `model.recipe.isPCOSAdapted`.
  - Display banner with "Undo" button when a swap is applied.
  - Display success banner when PCOS variation is created.

### Task 5: Build Gate & Verification
- Run `xcodegen generate` and `xcodebuild` targeting iOS Simulator.
- Verify `** BUILD SUCCEEDED **`.
