# Plan for Issue #6: UI: High-Fidelity Staggered Recipe Grid

Link: https://github.com/DanielxFigueroa/nom-nom-project/issues/6

## Objective
Develop the main "Explore" screen, featuring a performant, visually appealing staggered grid of recipes.

## Tasks

### 1. Types and DB schema understanding
- Check if `recipes` table exists in Supabase.
- Define a `Recipe` type (id, title, image_url, household_id, etc.).

### 2. Create `RecipeList` Component
- Create `src/components/RecipeList.tsx`.
- Fetch all recipes associated with the user's `household_id` from Supabase.
- Implement a staggered masonry-style grid layout.
- Use `expo-image` (`Image` component from `expo-image`) for rendering images.

### 3. Update the Explore Screen
- Ensure `/app/(tabs)/index.tsx` (or similar main app screen) uses the `RecipeList` component.

### 4. Tests
- Add a simple Jest test to verify rendering.

### 5. Finalize
- Run tests and ensure they pass.
- Commit using prefix `[AGY:Gemini-3.5-Flash]`.
- Open a PR.
