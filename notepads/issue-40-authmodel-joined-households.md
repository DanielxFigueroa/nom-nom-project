# Issue #40: M4: iOS — Update AuthModel to load all joined households

Link to issue: https://github.com/DanielxFigueroa/nom-nom-project/issues/40

## Objective
Extend `AuthModel` to maintain a list of all households the user has joined (`joinedHouseholds`), keeping `householdId` as the primary owned household.

## Plan

1. **Update `AuthModel` (`nom-nom-app/NomNom/Auth/AuthModel.swift`)**
   - Instantiate `private let householdRepository = HouseholdRepository()`.
   - Add property `var joinedHouseholds: [Household] = []`.
   - Add computed property `var joinedHouseholdIds: [UUID] { joinedHouseholds.map(\.id) }`.
   - Add method `func refreshJoinedHouseholds() async` which calls `householdRepository.fetchJoinedHouseholds(userID:)`.
   - Update `refreshProfile()` to await `refreshJoinedHouseholds()`.
   - Update `start()` auth state change listener to handle `.signedOut` by clearing `joinedHouseholds = []`.

2. **Verify iOS Build**
   - Run `xcodegen generate` and `xcodebuild` for iOS Simulator target.
   - Confirm `** BUILD SUCCEEDED **`.

3. **Commit & Push**
   - Commit changes with message referencing `Closes #40`.
   - Push branch `issue-40-authmodel-joined-households`.
   - Open Pull Request.
