# Issue 54: M5: iOS — Update HouseholdMember & Household models + repository methods for approval & role management

Link to Issue: https://github.com/DanielxFigueroa/nom-nom-project/issues/54

## Overview
Update `HouseholdMember` and `Household` Swift models to support `status`, `role`, and `require_approval`. Add repository methods for member approval management, pending request fetching, member removal/leaving, household owner retrieval, and approval settings updates. Update `joinHousehold` to respect `require_approval` and update `AuthModel` to expose `isOwner(of:)` and `pendingRequestCounts`.

## Tasks

1. **Models**
   - `NomNom/Models/HouseholdMember.swift`: Update `HouseholdMember` with nested `MemberStatus` and `MemberRole` enums, `status` and `role` properties, `var id: UUID { householdId }`, coding keys, custom decoding fallbacks, and typealiases for compatibility.
   - `NomNom/Models/Household.swift`: Update `Household` with `var requireApproval: Bool`, coding key `require_approval`, and custom decoder defaulting to `false`.

2. **Repository Methods (`NomNom/Auth/HouseholdRepository.swift`)**
   - `fetchPendingRequests(householdID:) async throws -> [HouseholdMember]`
   - `fetchActiveMembers(householdID:) async throws -> [HouseholdMember]`
   - `acceptMember(userID:householdID:) async throws`
   - `acceptMembers(userIDs:householdID:) async throws` (batch)
   - `declineMember(userID:householdID:) async throws`
   - `removeMember(userID:householdID:) async throws`
   - `leaveHousehold(userID:householdID:) async throws`
   - `updateApprovalSetting(householdID:requireApproval:) async throws`
   - `fetchHouseholdOwner(householdID:) async throws -> HouseholdMember?`
   - `fetchUserMemberships(userID:) async throws -> [HouseholdMember]`
   - Update `joinHousehold(userID:householdID:status:role:)`:
     - Checks `household.requireApproval` if `status` is not explicitly passed.
     - Sets `status = 'pending'` if `requireApproval == true`, else `'active'`.
     - Supports setting `role` (e.g. `'owner'` for creator/linkProfile).
   - Update `HouseholdMemberInsert` to include `status` and `role`.

3. **AuthModel Updates (`NomNom/Auth/AuthModel.swift`)**
   - Add `userMemberships: [HouseholdMember]` and `pendingRequestCounts: [UUID: Int]`.
   - Add computed method `isOwner(of householdID: UUID) -> Bool`.
   - In `refreshJoinedHouseholds()`, fetch user memberships and populate `pendingRequestCounts` for owned households.
   - Clear memberships and pending counts on sign out.

4. **Build Verification (iOS Build Gate)**
   - Run `xcodegen generate` and `xcodebuild`.
   - Confirm `** BUILD SUCCEEDED **`.
