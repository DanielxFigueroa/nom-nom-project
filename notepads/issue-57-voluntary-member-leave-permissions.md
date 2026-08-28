# Issue 57: M5: iOS — Voluntary member leave action & read-only recipe permission enforcement

Link to Issue: https://github.com/DanielxFigueroa/nom-nom-project/issues/57

## Overview
Implement voluntary member leave functionality in `HouseholdDetailView` for non-owner members, and strictly enforce read-only recipe permissions for non-owner members across the iOS application (`ExploreView`, `RecipeDetailView`, `AddRecipeView`, `EditRecipeView`, and `FolderManagerView`).

## Tasks

1. **Voluntary Member Leave in `HouseholdDetailModel` & `HouseholdDetailView`**
   - In `HouseholdDetailModel`: Add `leaveHousehold(auth: AuthModel, recipesRefresh: RecipesRefresh?)` that calls `repository.leaveHousehold(userID:householdID:)`, refreshes auth (`auth.refreshJoinedHouseholds()`), updates primary `auth.householdId` if needed, and triggers recipe refresh.
   - In `HouseholdDetailView`:
     - Show a "Leave Household" button at the bottom of the list for non-owners (`!isOwner`).
     - Present confirmation alert: `"Leave [household name]? You will lose access to all recipes in this household."` with Cancel / Leave (destructive).
     - Dismiss view after successfully leaving.

2. **Recipe & Household Dismissal Edge Case**
   - In `RecipeDetailView`: Add an `onChange(of: auth.joinedHouseholdIds)` observer to automatically `dismiss()` if the user leaves the household associated with the recipe being viewed.

3. **Read-Only Permission Enforcement across Views**
   - **`RecipeDetailView`**:
     - Update `isOwner` to `auth.isOwner(of: model.recipe.householdId)`.
     - Hide Edit (`square.and.pencil`) and Move to Folder (`folder.badge.plus`) toolbar buttons for non-owners.
     - Hide interactive folder picker button for non-owners (show read-only folder capsule if in a folder, or hide when no folder).
     - Keep serving size stepper interactive for all members.
   - **`AddRecipeView`**:
     - Check `auth.isOwner(of: householdID)`. If non-owner, display a `ContentUnavailableView` stating that only household owners can add recipes.
   - **`FolderManagerView`**:
     - Check `auth.isOwner(of: householdID)`.
     - Hide the create folder toolbar button (`folder.badge.plus`) for non-owners.
     - Hide the ellipsis edit menu (rename/subfolder/delete) on folder rows for non-owners.
     - Adjust empty state message for non-owners.

4. **iOS Build Gate & Verification**
   - Run `xcodegen generate`.
   - Run `xcodebuild` targeting iOS Simulator.
   - Ensure `** BUILD SUCCEEDED **`.
