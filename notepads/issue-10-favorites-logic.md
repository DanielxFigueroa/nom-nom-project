# Issue 10: Feature: Favorites & Bookmarking Logic
Link: https://github.com/DanielxFigueroa/nom-nom-project/issues/10

## Objective
Allow users to bookmark their favorite recipes and view them in a dedicated Favorites tab/screen within the application.

## Tasks & Technical Strategy

### 1. Database Migration & Schema
- Create a Supabase migration (`recipe-app/supabase/migrations/20260322040000_add_is_favorite_to_recipes.sql`):
  - Add `is_favorite` column (`BOOLEAN DEFAULT FALSE`) to `public.recipes` if it doesn't exist.
  - Create a Supabase function `public.toggle_recipe_favorite(recipe_id_param UUID, is_fav_param BOOLEAN)` to update `is_favorite` for the recipe.
- Update `Recipe` interface in `recipe-app/src/types/recipe.ts` to include `is_favorite?: boolean`.

### 2. Recipe Detail Modal (`recipe-app/app/modal.tsx`)
- Add a favorite toggle button (heart icon using `MaterialIcons` or `Ionicons`) in the header right or on the hero image/title section of `ModalScreen`.
- Support toggling favorite status optimistically in local state, and call `supabase.rpc('toggle_recipe_favorite', { recipe_id_param: id, is_fav_param: newValue })` (with fallback to `.from('recipes').update({ is_favorite: newValue }).eq('id', id)`).
- Ensure accessible touch targets and visual feedback (e.g., filled red heart vs outlined heart).

### 3. Favorites Screen (`recipe-app/app/(tabs)/favorites.tsx`) & RecipeList
- Update `RecipeList` component (`recipe-app/components/RecipeList.tsx`) to accept optional props, e.g. `onlyFavorites?: boolean`, or create a reusable component for filtering favorites.
- When `onlyFavorites={true}`, query Supabase recipes table filtering by `household_id = user.householdId` AND `is_favorite = true`.
- If no favorites exist, show a helpful empty state: "No favorite recipes yet. Bookmark recipes to view them here!".
- Update `favorites.tsx` tab screen to render `RecipeList` with `onlyFavorites`.

### 4. Branch & Git Workflow
- Create git branch `issue-10-favorites-logic`.
- Implement changes step by step.
- Add independent Jest unit tests in `recipe-app/app/__tests__/favorites.test.tsx` and update `recipe-app/app/__tests__/modal.test.tsx`.
- Run full test suite and verify everything passes.
- Commit changes with prefix `AGY:Gemini-3.6-Flash`.
- Open a GitHub Pull Request and request review.
