# Issue #44: M4: iOS — Display owned household invite code in AccountView

Link to issue: https://github.com/DanielxFigueroa/nom-nom-project/issues/44

## Objective
Update the Account Settings sheet (`AccountView`) to prominently display the invite code of the user's owned household so they can easily copy and share it with people they want to invite.

## Plan

1. **Update `AccountView` state and task lifecycle**
   - Add `@State private var ownedHousehold: Household?`
   - Add `@State private var copied = false`
   - Add `.task` modifier on `AccountView` that checks `auth.householdId` and fetches the `Household` via `HouseholdRepository().fetchHousehold(id: id)`.

2. **Update Household section in `AccountView`**
   - If `auth.householdId != nil`:
     - Section title: `"My Household"`
     - If `let household = ownedHousehold`:
       - Display `LabeledContent("Name", value: household.name ?? "My Household")`
       - Display invite code row with styled monospaced text, tint color, letter tracking, and a Copy button.
       - Copy button sets `UIPasteboard.general.string = household.inviteCode`, sets `copied = true`, and resets after 2 seconds.
     - Else:
       - Display `ProgressView()` while loading.
     - Keep `LabeledContent("Household ID", value: auth.householdId?.uuidString ?? "—")` with `.foregroundStyle(.secondary)` and `.font(.caption)` for debugging.
   - If `auth.householdId == nil`:
     - Display a message: `"You haven't created a household. Create one in the Households tab."`

3. **Verify iOS Build**
   - Run `xcodegen generate` and `xcodebuild` targeting iOS Simulator.
   - Verify `** BUILD SUCCEEDED **`.

4. **Commit, Push & Open PR**
   - Commit with message: `[AGY:Gemini-3.6-Flash] M4: iOS — Display owned household invite code in AccountView (Closes #44)`
   - Push branch `issue-44-display-owned-household-invite-code`
   - Open Pull Request.
