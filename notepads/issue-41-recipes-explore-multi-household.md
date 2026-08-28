# Issue #41: M4: iOS — Update RecipesRepository + ExploreModel for multi-household recipe fetching

Link to issue: https://github.com/DanielxFigueroa/nom-nom-project/issues/41

## Objective
Update `RecipesRepository` to fetch recipes across multiple household IDs, update `ExploreModel` to use all of the user's joined household IDs with a household-scoping filter, and update `FavoritesModel` / `FavoritesView` to show favorited recipes from all joined households.

## Tasks

1. **`RecipesRepository` (`nom-nom-app/NomNom/Recipes/RecipesRepository.swift`)**
   - Add `fetchRecipes(householdIDs: [UUID], onlyFavorites: Bool)` overload using PostgREST `.in("household_id", values: householdIDs)`.
   - Retain single-household `fetchRecipes(householdID: UUID, onlyFavorites: Bool)` by delegating to `fetchRecipes(householdIDs: [householdID], onlyFavorites: onlyFavorites)`.

2. **`TagsRepository` & `FoldersRepository` (`nom-nom-app/NomNom/Recipes/TagsRepository.swift`, `FoldersRepository.swift`)**
   - Add `fetchTags(householdIDs: [UUID])` overload to fetch tags across joined households.
   - Add `fetchFolders(householdIDs: [UUID])` overload to fetch folders across joined households.

3. **`ExploreModel` (`nom-nom-app/NomNom/Recipes/ExploreModel.swift`)**
   - Add `joinedHouseholds: [Household] = []` and `selectedHouseholdID: UUID? = nil`.
   - Update `load(householdIDs: [UUID], joinedHouseholds: [Household] = []) async` to fetch multi-household recipes, tags, and folders.
   - Update `filteredRecipes` to apply `selectedHouseholdID` scoping filter before text/tag/folder filters.
   - Update `clearFilters()` to reset `selectedHouseholdID = nil`.
   - Update `hasActiveFilters` to include `selectedHouseholdID != nil`.

4. **`PillFilterBar` & `ExploreView` (`nom-nom-app/NomNom/Components/PillFilterBar.swift`, `NomNom/Recipes/ExploreView.swift`)**
   - In `PillFilterBar`, add Household filter pill and sheet when `joinedHouseholds.count > 1`.
   - In `ExploreView`, pass `auth.joinedHouseholdIds` and `auth.joinedHouseholds` to `model.load()`.

5. **`FavoritesModel` & `FavoritesView` (`nom-nom-app/NomNom/Recipes/FavoritesModel.swift`, `NomNom/Recipes/FavoritesView.swift`)**
   - Update `FavoritesModel` to support `load(householdIDs: [UUID])` fetching across all joined households.
   - Update `FavoritesView` load calls to pass `auth.joinedHouseholdIds`.

6. **Testing & Verification**
   - Build using `xcodebuild` targeting iOS simulator.
   - Commit with clear prefix `[AGY:Gemini-3.6-Flash]`.
