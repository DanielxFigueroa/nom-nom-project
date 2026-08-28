# Issue #68: iOS — Export ingredients to Apple Reminders with one-click prompt

Link to issue: https://github.com/DanielxFigueroa/nom-nom-project/issues/68

## Summary
Enable users to export a recipe's ingredient list (scaled to the current serving size) directly into Apple Reminders with a single tap, creating organized grocery checklist items.

## Implementation Plan

### Task 1: Permissions in Info.plist
- Add `NSRemindersUsageDescription` and `NSRemindersFullAccessUsageDescription` to `nom-nom-app/NomNom/Resources/Info.plist`.

### Task 2: Create RemindersService
- Create `nom-nom-app/NomNom/Core/RemindersService.swift`.
- Implement authorization checking (`EKEventStore.authorizationStatus(for: .reminder)`).
- Implement async request authorization (`requestFullAccessToReminders()` / `requestAccess(to: .reminder)`).
- Implement reminder creation targeting the default Reminders calendar or creating/finding list.
- Handle error states: access denied, access restricted, no calendar found.

### Task 3: Update RecipeDetailModel
- Add Reminders export state (`isExporting`, `exportSuccessMessage`, `showRemindersPermissionAlert`, `remindersErrorMessage`).
- Add method `exportIngredientsToReminders(onlyUnchecked: Bool)` that compiles formatted scaled labels for selected ingredients and calls `RemindersService`.
- Provide computed helpers for export options (total count vs. unchecked count).

### Task 4: Update RecipeDetailView UI
- Add an "Export to Reminders" button in the Ingredients section.
- If some items are checked, offer a Menu or direct option for "Export All Ingredients" and "Export Unchecked Only".
- Show progress / spinner during export.
- Display a floating or inline animated success feedback badge / banner when export succeeds (e.g. "Added 5 ingredients to Reminders").
- Present alert if Reminders permission is denied with a direct shortcut to iOS Settings.

### Task 5: Build Gate & Testing
- Run `xcodegen generate` and `xcodebuild` for iOS Simulator.
- Verify `** BUILD SUCCEEDED **`.
