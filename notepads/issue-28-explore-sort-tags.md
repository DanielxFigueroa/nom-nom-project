# Issue 28 — Explore sort options + tag filtering

Link: Issue #28 (`M3: Explore sort options + tag filtering`)

## Objective
Add sort options and tag filtering to the Explore screen (`ExploreView` and `ExploreModel`), building the shared filter/sort model that supports sorting (newest, oldest, A-Z, Z-A, favorites first) and multi-select tag filtering combined with search.

## Changes Planned

1. **`NomNom/Models/Recipe.swift`**
   - Add `var tags: [Tag]?` field to `Recipe` struct.
   - Update `CodingKeys`, initializer, and `Decodable` initializer to support optional `tags`.

2. **`NomNom/Recipes/RecipesRepository.swift`**
   - Update `fetchRecipes` PostgREST select query from `*, ingredients(*)` to `*, ingredients(*), tags(*)` so recipe tags are fetched along with recipes.

3. **`NomNom/Recipes/ExploreModel.swift`**
   - Add `enum RecipeSort: String, CaseIterable, Identifiable`:
     - `.newest` ("Newest")
     - `.oldest` ("Oldest")
     - `.titleAsc` ("Title (A–Z)")
     - `.titleZ` ("Title (Z–A)")
     - `.favoritesFirst` ("Favorites First")
   - Add state properties:
     - `var sort: RecipeSort = .newest`
     - `var selectedTagIDs: Set<UUID> = []`
     - `var availableTags: [Tag] = []`
   - Update `load(householdID:)` to concurrently fetch recipes AND household tags.
   - Update `filteredRecipes` to:
     1. Filter by `searchQuery` (title or ingredient match).
     2. Filter by `selectedTagIDs` (if non-empty, ensure recipe contains all selected tags).
     3. Sort by `sort` choice.
   - Add `toggleTagSelection(_ tagID: UUID)`.

4. **`NomNom/Recipes/ExploreView.swift`**
   - Add a Sort `Menu` in the toolbar (or toolbar item) allowing the user to select the active sort option.
   - Add a horizontal tag chip strip under the search bar displaying `availableTags` as multi-selectable capsule chips with active accent styling (`Color.nnTint`).

5. **`NomNom/Recipes/FavoritesModel.swift`** (Optional reuse / consistency)
   - Ensure `FavoritesModel` works seamlessly if tags/sorting are accessed.

6. **Verification**
   - Run `xcodegen generate` and `xcodebuild` for iOS Simulator.
   - Ensure `** BUILD SUCCEEDED **`.
