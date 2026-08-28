# Issue #27: Tags + PCOS toggle-tag (remove free-text PCOS/meal-timing UI)

Link to issue: https://github.com/DanielxFigueroa/nom-nom-project/issues/27

## Summary
Add household-scoped, user-defined **tags** with a reserved **PCOS** tag toggled at
creation. **Remove the free-text PCOS/meal-timing UI** (columns stay in the DB, unused —
no destructive migration, no data loss). Meal timing becomes ordinary tags
(Breakfast/Lunch/Dinner).

## Implementation Plan

### Task 1: Supabase Migration — `create_tags.sql`
Create `supabase/migrations/20260802180000_create_tags.sql`:
- `tags` table: `id`, `household_id`, `name`, `is_pcos`, `created_at`, unique constraint on `(household_id, lower(name))`.
- `recipe_tags` join table: `recipe_id`, `tag_id`, composite PK.
- RLS policies: household-scoped for `tags` (same `household_id = (select household_id from profiles where id = auth.uid())` pattern); `recipe_tags` gated via the parent recipe's household.

### Task 2: Tag Model — `Models/Tag.swift`
Create `Tag` struct: `id`, `householdId`, `name`, `isPCOS`, `createdAt`.
Codable with snake_case coding keys.

### Task 3: Recipe Model Update — add `tags: [Tag]?`
- Add `tags: [Tag]?` property to `Recipe.swift`.
- Add `tags` to `CodingKeys`, `init(...)`, `init(from:)`.

### Task 4: Tags Repository — `Recipes/TagsRepository.swift`
Create `TagsRepository`:
- `fetchTags(householdID:)` → `[Tag]`
- `createTag(name:householdID:)` → `Tag`
- `ensurePCOSTag(householdID:)` → `Tag` (upsert; check if exists first)
- `setRecipeTags(recipeID:tagIDs:)` → delete existing recipe_tags + insert new

### Task 5: Recipes Repository Update
- Update `fetchRecipes` select to `"*, ingredients(*), tags:recipe_tags(tag:tags(*))"` or use the Supabase join syntax for `recipe_tags`.
- Actually: Supabase PostgREST can join through junction tables. The correct syntax for fetching tags through recipe_tags is:
  `select("*, ingredients(*), recipe_tags(tags(*))")` 
  Then flatten in the model, or adjust the Recipe model to decode through the junction.
- Alternative simpler approach: keep Recipe.tags as-is and populate tags separately in the detail model/form model. This avoids complex join decoding.
- **Decision**: Populate tags via a separate `TagsRepository.fetchRecipeTags(recipeID:)` call in detail/form, rather than complicating the list query. Tag chips on the detail view will be loaded in `RecipeDetailModel.load()`.

### Task 6: RecipesRepository — Pass tagIDs through create/update
- `createRecipe` accepts optional `tagIDs: [UUID]` and calls `TagsRepository.setRecipeTags` after insert.
- `updateRecipe` accepts optional `tagIDs: [UUID]` and calls `TagsRepository.setRecipeTags` after update.
- Update `RecipeInput` to carry `tagIDs`.

### Task 7: RecipeFormModel — Drop PCOS/meal-timing, add tags
- Remove `insulinIndexNotes` and `mealTimingSuggestions` properties.
- Add `selectedTagIDs: Set<UUID>`, `isPCOS: Bool`, `availableTags: [Tag]`.
- Add `loadTags(householdID:)` async method to fetch available tags and ensure PCOS tag exists.
- Add `createTag(name:householdID:)` for inline tag creation.
- Update `buildPayload()` to include tag IDs (PCOS tag added/removed based on toggle).
- Update `init(recipe:ingredients:)` to load existing tags.

### Task 8: RecipeFormView — UI changes on details step
- **Remove** "Insulin Index Notes" and "Meal Timing Suggestions" fields from step 1.
- **Add** a PCOS Toggle (`Toggle("PCOS Recipe", isOn: $model.isPCOS)`).
- **Add** a tag editor section: chips of available household tags (selectable), + "Add tag" inline creation.

### Task 9: RecipeDetailModel — Load tags, remove PCOS guidance
- Add `tags: [Tag]` property.
- In `load()`, also fetch recipe tags via `TagsRepository.fetchRecipeTags(recipeID:)`.
- Remove/deprecate `hasPCOSGuidance` (will no longer show free-text PCOS cards).

### Task 10: RecipeDetailView — Remove PCOS cards, add tag chips
- **Remove** `pcosSection` and the `PCOSGuidanceCard` usage for free-text PCOS/meal-timing.
- **Add** tag chips below the title. PCOS tag styled distinctly with `Color.nnTint` badge.
- Keep `PCOSGuidanceCard.swift` in codebase (unused, no destructive removal).

### Task 11: AddRecipeView + EditRecipeView — Pass householdID for tags
- `AddRecipeView`: call `model.loadTags(householdID:)` on appear.
- `EditRecipeView`: call `model.loadTags(householdID:)` + load existing recipe tags.
- Both pass `tagIDs` through to `createRecipe`/`updateRecipe`.

### Task 12: Build Verification
- Run `xcodegen generate` and `xcodebuild` gate to verify `** BUILD SUCCEEDED **`.
