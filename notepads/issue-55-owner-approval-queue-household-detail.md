# Issue 55: M5: iOS — Owner approval queue & member removal UI (HouseholdDetailView)

Link to Issue: https://github.com/DanielxFigueroa/nom-nom-project/issues/55

## Overview
Build the owner-facing member management screen: a household detail view showing pending join requests with accept/decline actions (including batch "Accept All Selected"), an active member list with remove capability, and a `require_approval` toggle in household settings. Also update `HouseholdsView` with navigation to the detail screen and pending badge indicators.

## Plan & Tasks

1. **Models & Components**
   - `NomNom/Models/HouseholdMember.swift`: Update `var id: UUID { userId }` so multiple members in the same household have distinct IDs, and add display helper methods.
   - `NomNom/Households/PendingRequestRow.swift`: Create row component with:
     - Checkbox toggle for multi-selection.
     - User identifier / display name and request time.
     - Accept (✅, `.buttonStyle(.borderedProminent)`, `.tint(.green)`) and Decline (✕, `.buttonStyle(.bordered)`, `.tint(.red)`) buttons.
     - Swipe action to decline.
   - `NomNom/Households/MemberRow.swift`: Create row component with:
     - User display name / email.
     - Role badge (`Owner` ⭐ / `Member` 👤).
     - Context menu with "Remove from Household" for non-owners when viewer is owner.
     - Callback/action to trigger remove confirmation dialog.

2. **ViewModel (`NomNom/Households/HouseholdDetailModel.swift`)**
   - `@Observable` view model holding:
     - `household: Household`
     - `activeMembers: [HouseholdMember]`
     - `pendingRequests: [HouseholdMember]`
     - `selectedPendingIDs: Set<UUID>`
     - `requireApproval: Bool`
     - `isOwner: Bool`
     - `isLoading: Bool`
     - `errorMessage: String?`
     - `memberToRemove: HouseholdMember?`
   - Methods:
     - `load(auth: AuthModel)`: Fetch latest household, active members, pending requests (if owner), sync `requireApproval`.
     - `acceptRequest(_ member: HouseholdMember, auth: AuthModel)`: Accept single member, refresh lists and `auth.refreshJoinedHouseholds()`.
     - `declineRequest(_ member: HouseholdMember, auth: AuthModel)`: Decline single member, refresh lists and `auth.refreshJoinedHouseholds()`.
     - `acceptSelected(auth: AuthModel)`: Batch accept selected pending IDs, clear selection, refresh lists and `auth.refreshJoinedHouseholds()`.
     - `removeMember(_ member: HouseholdMember, auth: AuthModel)`: Remove member, refresh lists and `auth.refreshJoinedHouseholds()`.
     - `toggleApprovalSetting(_ newValue: Bool)`: Update `require_approval` via repository and update local state.
     - `toggleSelection(for memberID: UUID)`: Add/remove ID from `selectedPendingIDs`.

3. **View (`NomNom/Households/HouseholdDetailView.swift`)**
   - Navigation title with household name / display name.
   - Pending Requests Section (visible to owner only, when count > 0):
     - Section header with count badge.
     - ForEach with `PendingRequestRow`.
     - "Accept All Selected" button (disabled when no checkboxes selected).
   - Active Members Section:
     - Header "Members (\(activeMembers.count))".
     - ForEach with `MemberRow`.
     - Remove confirmation `.alert` dialog ("Remove [name]? They will lose access to all recipes in [household name].").
   - Household Settings Section (visible to owner only):
     - "Require approval for new members" toggle with explanation text.
   - Pull-to-refresh (`.refreshable`).

4. **Navigation & Badging in `NomNom/Households/HouseholdsView.swift`**
   - Wrap household rows in `NavigationLink(destination: HouseholdDetailView(household: household))`.
   - Add pending request badge (orange capsule matching Owner badge) when `auth.pendingRequestCounts[household.id, default: 0] > 0`.

5. **iOS Build Gate & Verification**
   - Run `xcodegen generate`.
   - Run `xcodebuild` targeting iOS simulator.
   - Verify `** BUILD SUCCEEDED **`.
