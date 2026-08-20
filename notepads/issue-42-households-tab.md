# Issue #42: M4: iOS — HouseholdsView tab: list joined households + Join Household flow

Link to issue: https://github.com/DanielxFigueroa/nom-nom-project/issues/42

## Objective
Add a new **Households** tab to `MainTabView` (fourth tab, house icon) listing all households the user has joined, showing each household's name and recipe count, and providing the **Join Household** UI (code text field + Join button).

## Tasks

1. **`RecipesRepository` (`nom-nom-app/NomNom/Recipes/RecipesRepository.swift`)**
   - Add `fetchRecipeCounts(householdIDs: [UUID]) async throws -> [UUID: Int]` helper to retrieve recipe counts per household.

2. **`RecipesRefresh` (`nom-nom-app/NomNom/Core/RecipesRefresh.swift`)**
   - Add `Notification.Name.recipesRefresh` extension for broadcasting reload events.

3. **`JoinHouseholdModel` (`nom-nom-app/NomNom/Households/JoinHouseholdModel.swift`)**
   - `@MainActor @Observable` class managing `inviteCode`, `isLoading`, `errorMessage`, `successMessage`.
   - `join(auth: AuthModel, recipesRefresh: RecipesRefresh?)` calls `repository.findHousehold` and `repository.joinHousehold`, refreshes `auth.joinedHouseholds`, and triggers recipe refresh notifications.

4. **`HouseholdsView` (`nom-nom-app/NomNom/Households/HouseholdsView.swift`)**
   - Navigation title **"Households"**.
   - Section **"Join a Household"**: text field auto-uppercased (max 6 chars), Join button, and inline feedback labels.
   - Section **"My Households"**: list of `auth.joinedHouseholds` with household name, recipe count, invite code, and owner indicator (`household.id == auth.householdId`).
   - Refresh recipe counts on load/appear and after joining.

5. **`MainTabView` (`nom-nom-app/NomNom/App/MainTabView.swift`)**
   - Add fourth tab: `HouseholdsView().tabItem { Label("Households", systemImage: "house") }`.

6. **iOS Build Gate & Verification**
   - Run `xcodegen generate` and `xcodebuild` for iOS Simulator.
   - Ensure build passes with `** BUILD SUCCEEDED **`.
   - Commit & push changes with reference `Closes #42`.
