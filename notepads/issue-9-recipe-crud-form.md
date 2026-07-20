# Issue 9: Feature: Recipe CRUD Form
Link: https://github.com/DanielxFigueroa/nom-nom-project/issues/9

## Objective
Enable users to create, update, and delete recipes through a user-friendly, high-fidelity multi-step form that integrates with Supabase Storage for image uploads and includes dynamic ingredient management, database operations, and a delete button with a confirmation dialog.

## Technical Plan

### 1. Branch Setup
- Create and check out a new branch: `issue-9-recipe-crud-form` (based on `issue-8-recipe-detail-modal`).

### 2. Dependency Installation
- Install `expo-image-picker` to support selecting image files on iOS/Android/Web.
  - Run: `npx expo install expo-image-picker` or `npm install expo-image-picker`.

### 3. Database Storage Configuration & Migration
- Create a Supabase migration to initialize a public bucket named `recipes` if it doesn't already exist.
- Add RLS policies for storage bucket access so that authenticated users can upload and retrieve images from the `recipes` bucket.

### 4. Create Reusable RecipeForm Component (`recipe-app/components/RecipeForm.tsx`)
- Implement a modern, multi-step form layout (3 Steps):
  - **Step 1: Details**
    - Input fields: `title` (text, required), `description` (multiline text).
    - Image selection: Integrates with `expo-image-picker` to select from gallery.
    - Image upload: Handles uploading the file to Supabase Storage `recipes` bucket and saving the public URL.
  - **Step 2: Ingredients**
    - Dynamic sub-form allowing users to add, edit, and remove ingredients.
    - Fields per ingredient: `quantity`, `unit`, `name` (required).
    - Add a PCOS dietary warning if an ingredient name contains seafood terms (as defined in `food_substitutions.md`), prompting the user to select an alternative.
  - **Step 3: Instructions**
    - Large multiline text input for `instructions` (supports Markdown).
- Layout: Progress indicator, navigation buttons (Back/Next/Save).
- Aesthetics: High-fidelity styling matching the existing Dark/Light theme, custom themed inputs, micro-animations/hover-states (using `Pressable` opacity changes), and clean typography.

### 5. Create/Update Screens
- **Add Recipe Screen (`recipe-app/app/(tabs)/add-recipe.tsx`)**:
  - Render `RecipeForm` in "add" mode.
  - On submit: Insert the new recipe into `recipes` table (with user's `household_id` from `AuthContext`), insert nested `ingredients` rows, and clear form state.
  - Navigate the user back to the Explore feed.
- **Edit Recipe Screen (`recipe-app/app/edit-recipe.tsx`)**:
  - Create a new modal screen in `recipe-app/app/edit-recipe.tsx`.
  - Fetch existing recipe and its ingredients using the passed `id` parameter.
  - Render `RecipeForm` pre-populated with these values.
  - On submit: Update the recipe in Supabase, replace/update its ingredients, and go back.
  - Render a "Delete Recipe" button with a native `Alert` confirmation dialog.
- **Root Stack Configuration (`recipe-app/app/_layout.tsx`)**:
  - Add the `edit-recipe` screen as a modal Stack screen:
    `<Stack.Screen name="edit-recipe" options={{ presentation: 'modal', title: 'Edit Recipe' }} />`
- **Recipe Detail Screen (`recipe-app/app/modal.tsx`)**:
  - Add an "Edit" icon/button in the navigation header (rendered only if the recipe belongs to the logged-in user's household).
  - Pressing the edit button triggers: `router.push({ pathname: '/edit-recipe', params: { id } })`.

### 6. Testing
- Create a Jest test file `recipe-app/app/__tests__/edit-recipe.test.tsx` and/or `recipe-app/components/__tests__/RecipeForm.test.tsx` to verify:
  - Form steps navigation.
  - Validation.
  - Dynamic ingredient addition/deletion.
  - Image uploader triggering.
  - Save and delete handlers.
- Run the Jest suite to ensure all tests pass.
