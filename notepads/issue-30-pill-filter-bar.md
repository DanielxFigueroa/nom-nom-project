# Issue 30 — Collectr-style pill-dropdown filter bar on Explore

Link: https://github.com/DanielxFigueroa/nom-nom-project/issues/30

## Overview
Surface sort options, tag filters, and folder selection through a horizontal row of pill-shaped dropdown controls (`PillFilterBar` and `PillDropdown`) at the top of the Explore tab. Scopes the recipe grid by search, active tags, and selected folder (including subfolders), with breadcrumb navigation for nested folders.

## Plan

1. **Create `Components/PillDropdown.swift`**:
   - Reusable pill dropdown wrapping SwiftUI `Menu`.
   - Parameters: `icon` (SF Symbol), `label` (String), `isActive` (Bool), `content` (ViewBuilder for menu items).
   - Styled with capsule shape, `Color.nnTint` when active (white text) and `Color(.secondarySystemBackground)` when inactive (primary text), with leading icon and trailing `chevron.down`.

2. **Update `ExploreModel.swift`**:
   - Add `availableFolders: [Folder] = []` and `selectedFolderID: UUID? = nil`.
   - In `load(householdID:)`, asynchronously fetch recipes, tags, and folders using `FoldersRepository`.
   - Update `filteredRecipes` to filter by selected folder and its subfolder descendants.
   - Add helper functions for folder hierarchy (descendants computation, folder breadcrumb path, hierarchy display labels).

3. **Create `Components/PillFilterBar.swift`**:
   - Horizontal `ScrollView` displaying:
     - **Sort Pill**: single-select dropdown for `RecipeSort` options. Active if `sort != .newest`.
     - **Tags Pill**: multi-select dropdown for household tags. Active if `!selectedTagIDs.isEmpty`.
     - **Folder Pill**: single-select dropdown for available folders (with hierarchy indenting/path). Active if `selectedFolderID != nil`.
     - Optional "Reset" button if any filter is active.

4. **Update `ExploreView.swift`**:
   - Replace toolbar Sort menu and inline `tagChipStrip` with `PillFilterBar` below `SearchBar`.
   - Add folder breadcrumb bar above grid when `selectedFolderID != nil`, allowing quick navigation back up the folder tree.

5. **Test iOS Build Gate**:
   - Run `xcodegen generate` and `xcodebuild` for iOS Simulator. Verify `** BUILD SUCCEEDED **`.
