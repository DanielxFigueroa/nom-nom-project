# Issue 29: M3: Nested folders — schema, repository, move-to-folder UI

Link to issue: [Issue 29](https://github.com/DanielxFigueroa/nom-nom-project/issues/29)

## Summary
Implement nested folder support for recipes in the native SwiftUI iOS app (`nom-nom-app/`).
Each recipe can belong to at most one folder (`folder_id`), and folders can be nested via `parent_id`.
Deleting a folder cascades to subfolders and un-files contained recipes (`on delete set null`).

## Plan

### 1. Database Migration
Create `supabase/migrations/20260804000000_create_folders.sql`:
- Create `folders` table (`id`, `household_id`, `name`, `parent_id`, `created_at`).
- Add `folder_id` column to `recipes` table (`references folders(id) on delete set null`).
- Enable Row Level Security (RLS) on `folders` table with household-scoped access.
- Apply migration via Supabase CLI and reload PostgREST schema cache.

### 2. Models & Data Layer
- **`Models/Folder.swift`**: Create struct `Folder` conforming to `Identifiable`, `Codable`, `Hashable`.
- **`Models/Recipe.swift`**: Add `folderId: UUID?` with `folder_id` coding key.
- **`Recipes/FoldersRepository.swift`**: Implement methods:
  - `fetchFolders(householdID: UUID) async throws -> [Folder]`
  - `createFolder(name: String, parentID: UUID?, householdID: UUID) async throws -> Folder`
  - `renameFolder(id: UUID, newName: String) async throws`
  - `deleteFolder(id: UUID) async throws`
  - `moveRecipe(recipeID: UUID, toFolder folderID: UUID?) async throws`
- **`Recipes/RecipesRepository.swift`**:
  - Update `RecipeInput`, `RecipeInsert`, `RecipeUpdate` to include `folder_id`.

### 3. Move-to-Folder & Folder Management UI
- **`Recipes/FolderPickerSheet.swift`**:
  - Sheet for selecting a folder for a recipe (or "None / Un-filed").
  - Includes inline "New folder..." action with parent selection.
- **`Recipes/FolderManagerView.swift`**:
  - Screen/Sheet to manage household folders (create, rename, delete, hierarchy view).
  - Reachable from `ExploreView` toolbar or `AccountView`.
- **`RecipeDetailView.swift` & `RecipeFormView.swift`**:
  - Integrate move-to-folder action in `RecipeDetailView` toolbar/header.
  - Integrate folder picker step/field in `RecipeFormModel` & `RecipeFormView`.

### 4. Build & Verification Gate
- Run `xcodegen generate` and `xcodebuild` targeting iOS Simulator.
- Ensure `** BUILD SUCCEEDED **`.
- Verify acceptance criteria.
