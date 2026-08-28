# Issue 56: M5: iOS — Approval-aware join flow & pending household UI state

Link to Issue: https://github.com/DanielxFigueroa/nom-nom-project/issues/56

## Overview
Update the join household flow across both `HouseholdsView` (in-app join) and `HouseholdSetupView` (onboarding join) to be approval-aware. When joining a household with `require_approval = true`, a pending membership is created with a waiting state rather than immediate active access. Display pending households with a distinct visual badge/styling in `HouseholdsView` without recipe counts or navigation.

## Tasks

1. **Repository Updates (`NomNom/Auth/HouseholdRepository.swift`)**
   - Add `fetchHousehold(inviteCode: String) async throws -> Household?` to look up a household by invite code with its `require_approval` flag.
   - Add `fetchMembership(userID: UUID, householdID: UUID) async throws -> HouseholdMember?` to check existing user membership in a household.
   - Add `fetchPendingHouseholds(userID: UUID) async throws -> [Household]` to retrieve households where the user has a `pending` status.
   - Ensure `joinHousehold(userID:householdID:status:role:)` performs an upsert allowing re-requesting from `declined` to `pending`.

2. **AuthModel Updates (`NomNom/Auth/AuthModel.swift`)**
   - Add `var pendingHouseholds: [Household] = []`.
   - Update `refreshJoinedHouseholds()` to load both active (`joinedHouseholds`) and pending memberships (`pendingHouseholds`).
   - Reset `pendingHouseholds` in `signOut()` and `refreshProfile()`.

3. **Join Household Flow (`NomNom/Households/JoinHouseholdModel.swift`)**
   - Validate invite code and fetch household details.
   - Check existing membership status:
     - `active`: Show "You are already a member of this household."
     - `pending`: Show "You already have a pending request for this household."
     - `declined` or none:
       - If `requireApproval == true`: Join as `pending`, refresh auth, show success: "Request sent! Waiting for the household owner to accept you."
       - If `requireApproval == false`: Join as `active`, refresh auth, show success: "Successfully joined household!", trigger recipe refresh.

4. **Households UI Updates (`NomNom/Households/HouseholdsView.swift`)**
   - Under "My Households", render both `auth.joinedHouseholds` (active) and `auth.pendingHouseholds` (pending).
   - Pending household rows:
     - Badge: "Pending" (orange/yellow capsule).
     - Subtitle: "Waiting for owner approval".
     - Dimmed/muted styling with `.opacity(0.6)`.
     - Do not show recipe counts.
     - Do not navigate to `HouseholdDetailView` (non-interactive row).
   - Active household rows maintain current behavior with navigation and recipe counts.
   - Show "No households joined yet." only if both joined and pending lists are empty.

5. **Household Setup Updates (`NomNom/Auth/HouseholdSetupModel.swift` & `NomNom/Auth/HouseholdSetupView.swift`)**
   - Handle approval-aware join during onboarding:
     - If the targeted household requires approval, set `isPendingApproval = true` and track the pending household.
     - In `HouseholdSetupView`, display a pending state banner/card explaining that the join request is awaiting owner approval, with options to wait or create a new household instead.

6. **iOS Build Gate & Verification**
   - Run `xcodegen generate`.
   - Run `xcodebuild` targeting iOS Simulator.
   - Ensure `** BUILD SUCCEEDED **`.
