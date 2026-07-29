# Issue #12: Feature: Multi-Column Client-Side Search

Link: https://github.com/DanielxFigueroa/nom-nom-project/issues/12

## Objective
Implement client-side search functionality on the "Explore" screen that filters recipes in the app's state based on matching recipe `title` or ingredient names.

## Proposed Tasks

1. **Component Design**:
   - Create `components/SearchBar.tsx` with search input field, clear icon, search icon, accessibility attributes, and proper theming.
   - Accepts `value`, `onChangeText`, and `onClear` props.

2. **State & Filtering in `RecipeList.tsx` and `ExploreScreen` (`app/(tabs)/index.tsx`)**:
   - Update `RecipeList`'s query to select `recipes` along with `ingredients` using Supabase relational select (`*, ingredients(*)`).
   - Update `Recipe` interface in `src/types/recipe.ts` to optionally include `ingredients?: Ingredient[]`.
   - Accept optional `searchQuery?: string` prop in `RecipeList`.
   - Implement client-side filtering in `RecipeList`:
     - Case-insensitive search on `recipe.title` OR `ingredient.name` for each recipe in state.
     - Display filtered recipes in the 2-column staggered layout.
     - Display a friendly empty state message when search query yields no results (e.g. `No recipes found matching "${searchQuery}"`).

3. **Explore Screen Integration**:
   - Add search state (`searchQuery`) and `SearchBar` component in `app/(tabs)/index.tsx`.
   - Pass `searchQuery` down to `RecipeList`.

4. **Testing**:
   - Add unit tests in `components/__tests__/SearchBar.test.tsx` for search bar interactions.
   - Update / add unit tests in `app/(tabs)/__tests__/index.test.tsx` and `components/__tests__/RecipeList.test.tsx` for client-side multi-column filtering by title and ingredient name.
   - Ensure full test suite passes.

5. **Branch & Git Commit**:
   - Ensure work is on a dedicated branch (`issue-12-search`).
   - Commit with clear prefix `[AGY:Gemini-3.6-Flash]`.
