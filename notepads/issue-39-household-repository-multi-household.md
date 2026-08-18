# Issue #39: M4: iOS — HouseholdRepository multi-household methods + HouseholdMember model

Link to issue: https://github.com/DanielxFigueroa/nom-nom-project/issues/39

## Objective
Extend the iOS data layer to support multiple households per user. Add a `HouseholdMember` model, new `HouseholdRepository` methods for fetching all joined households, fetching a household by ID, and joining via invite code, and update household creation and join flow to write to `household_members`.

## Plan

1. **Create Swift Model `HouseholdMember`**
   - File: `nom-nom-app/NomNom/Models/HouseholdMember.swift`
   - Define struct `HouseholdMember: Identifiable, Codable, Hashable` matching the `household_members` database table schema.
   - Coding keys: `user_id`, `household_id`, `joined_at`.

2. **Verify `Household` Model**
   - File: `nom-nom-app/NomNom/Models/Household.swift`
   - Ensure `name: String?` property and `case name` in `CodingKeys` are present.

3. **Update `HouseholdRepository`**
   - File: `nom-nom-app/NomNom/Auth/HouseholdRepository.swift`
   - Add `fetchJoinedHouseholds(userID: UUID) async throws -> [Household]`
   - Add `joinHousehold(userID: UUID, householdID: UUID) async throws`
   - Add `fetchHousehold(id: UUID) async throws -> Household?`
   - Update `findHousehold(inviteCode: String, userID: UUID? = nil) async throws -> UUID?`
   - Update `createHousehold(name: String? = nil, userID: UUID? = nil) async throws -> UUID`
   - Update `linkProfile(userID: UUID, householdID: UUID) async throws`

4. **Verify iOS Build**
   - Run `xcodegen generate` and `xcodebuild` for iOS Simulator target.
   - Confirm `** BUILD SUCCEEDED **`.

5. **Commit & Push**
   - Commit changes with message referencing `Closes #39`.
   - Push branch `issue-39-household-repository-multi-household`.
   - Open Pull Request.
