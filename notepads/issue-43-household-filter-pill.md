# Issue #43: M4: iOS — Household filter pill in ExploreView pill bar

Link to issue: https://github.com/DanielxFigueroa/nom-nom-project/issues/43

## Objective

Add a **Household** filter pill bar to the Explore screen when a user has joined multiple households (`auth.joinedHouseholds.count > 1`). Tapping a household pill scopes the recipe grid to that household. Tapping it again deselects it (returning to all households).

## Tasks

1. **`ExploreModel` (`nom-nom-app/NomNom/Recipes/ExploreModel.swift`)**
   - Update `selectedHouseholdID` property with a `didSet` observer: when `selectedHouseholdID` changes or is cleared, if `selectedFolderID` belongs to a different household (or the deselected household), reset `selectedFolderID = nil`.
   - Update `hierarchicalFolders()` to scope returned folders to `selectedHouseholdID` when `selectedHouseholdID != nil`.

2. **`PillFilterBar` (`nom-nom-app/NomNom/Components/PillFilterBar.swift`)**
   - Remove redundant `Household` dropdown pill and `HouseholdFilterSheet` sheet, leaving `Sort`, `Tags`, `Folder`, and `Reset` pills in `PillFilterBar`.

3. **`ExploreView` (`nom-nom-app/NomNom/Recipes/ExploreView.swift`)**
   - Add horizontal `ScrollView` of household pills above `PillFilterBar` when `auth.joinedHouseholds.count > 1`.
   - Style owned household pill (`household.id == auth.householdId`) with `house.fill` icon and joined households with `house` icon.
   - Update empty state messages:
     - If `selectedHouseholdID` set or recipes empty in household: `"No recipes in this household yet."`
     - Otherwise: `"No recipes found in your households."`

4. **Build Verification & PR**
   - Run `xcodegen generate` and `xcodebuild` targeting iOS simulator.
   - Ensure build prints `** BUILD SUCCEEDED **`.
   - Commit changes with prefix `[AGY:Gemini-3.6-Flash]` referencing `#43`.
   - Push branch `issue-43-household-filter-pill` and open PR.
