# Issue 58: M5: iOS — In-app badge indicators & ownership transfer

Link to Issue: https://github.com/DanielxFigueroa/nom-nom-project/issues/58

## Overview
Add in-app badge indicators for pending join requests (owner side) and ownership transfer capability in the native SwiftUI iOS app.

## Tasks & Plan

1. **Database / Migration (Supabase)**
   - Add `supabase/migrations/20260828000000_add_transfer_household_ownership_rpc.sql` with `public.transfer_household_ownership(p_household_id uuid, p_new_owner_id uuid)` RPC function.

2. **Repository (`HouseholdRepository.swift`)**
   - Implement `transferOwnership(householdID: UUID, newOwnerID: UUID, currentOwnerID: UUID) async throws`.
   - Call RPC `transfer_household_ownership` with graceful fallback to direct sequential updates.

3. **Auth Model (`AuthModel.swift`)**
   - Add computed property `var totalPendingCount: Int { pendingRequestCounts.values.reduce(0, +) }`.
   - Ensure `isOwner(of:)` and membership updates are kept up to date after transfers.

4. **Tab Bar & Households View Badges (`MainTabView.swift`, `HouseholdsView.swift`)**
   - `MainTabView`: Inject `AuthModel` via `@Environment(AuthModel.self)` and apply `.badge(auth.totalPendingCount)` to the Households tab.
   - `HouseholdsView`: Ensure `.task` and `.refreshable` invoke `await auth.refreshJoinedHouseholds()`.
   - `HouseholdsView`: Clean up `isOwner` check in `householdRow` to use `auth.isOwner(of: household.id)`. Show inline orange capsule badge with pending count when count > 0.

5. **Ownership Transfer UX & ViewModel (`HouseholdDetailModel.swift`, `HouseholdDetailView.swift`, `MemberRow.swift`)**
   - `MemberRow`: Add `onTransferOwnership: (() -> Void)?` and include "Transfer Ownership" item in the context menu for regular members when viewer is household owner.
   - `HouseholdDetailModel`: Add `memberToTransfer: HouseholdMember?`, `showTransferAlert: Bool`, and `transferOwnership(to:auth:) async -> Bool`.
   - `HouseholdDetailView`: Present confirmation alert `"Transfer ownership to \(memberName)? You will become a regular member and lose the ability to manage recipes and members."` with Cancel and Transfer actions.
   - After transfer, refresh auth profile and local household details.

6. **iOS Build Gate & Verification**
   - Run `xcodegen generate`.
   - Run `xcodebuild` targeting iOS Simulator.
   - Ensure `** BUILD SUCCEEDED **`.
