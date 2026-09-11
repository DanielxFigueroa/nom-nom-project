# Issue #73: PCOS Assistant: User Profile Preferences & Opt-In Settings

Link to issue: https://github.com/DanielxFigueroa/nom-nom-project/issues/73

## Summary
Implement an opt-in master toggle and personalized PCOS focus area preferences in `AccountView`.
Allow users to opt into the PCOS Nutrition Assistant from their Account settings and configure their personalized focus areas (insulin resistance, anti-inflammatory, high protein, dairy sensitivity, gluten sensitivity) and suggestion style (gentle additions vs direct swaps) so that suggestions are nuanced to their specific needs.

## Implementation Plan

### Task 1: Supabase Migration — `add_pcos_settings_to_profiles.sql`
- Create `supabase/migrations/20260831000000_add_pcos_settings_to_profiles.sql`.
- Add nullable `pcos_settings jsonb` column to `public.profiles`.

### Task 2: Data Models — `NomNom/Models/PCOSSettings.swift`
- Create `PCOSSettings` (Codable, Equatable, Hashable):
  - `isEnabled: Bool` (default `false`)
  - `focusAreas: Set<PCOSFocusArea>` (default `[]`)
  - `suggestionStyle: PCOSSuggestionStyle` (default `.gentleAdditions`)
- Create `PCOSFocusArea` enum (String, CaseIterable, Codable, Identifiable, Hashable):
  - `insulinResistance = "insulin_resistance"` ("Insulin Resistance", icon: "bolt.shield")
  - `inflammation = "inflammation"` ("Anti-Inflammatory", icon: "leaf")
  - `highProtein = "high_protein"` ("High Protein", icon: "figure.run")
  - `dairySensitivity = "dairy_sensitivity"` ("Dairy Sensitivity", icon: "cup.and.saucer")
  - `glutenSensitivity = "gluten_sensitivity"` ("Gluten Sensitivity", icon: "cross.vial")
- Create `PCOSSuggestionStyle` enum (String, CaseIterable, Codable, Identifiable, Hashable):
  - `gentleAdditions = "gentle_additions"` ("Gentle Additions")
  - `directSwaps = "direct_swaps"` ("Direct Swaps")
  - `displayName`, `description` helpers.
- Update `NomNom/Models/Profile.swift` with `pcosSettings: PCOSSettings?`.

### Task 3: Settings Store — `NomNom/Core/PCOSSettingsStore.swift`
- Create `@MainActor @Observable final class PCOSSettingsStore`.
- Persist settings locally in `UserDefaults` (`nom_nom_pcos_settings`).
- Provide methods to sync to/from Supabase `profiles` table when authenticated.
- Provide convenience methods: `toggleFocusArea(_:userID:)`, `setEnabled(_:userID:)`, `setSuggestionStyle(_:userID:)`.

### Task 4: UI Components — `NomNom/Auth/PCOSSettingsView.swift` & `AccountView.swift`
- Create `PCOSSettingsView.swift` with:
  - Master toggle: "Enable PCOS Recipe Assistant" with subtitle.
  - Collapsible/animated section when enabled:
    - Chip pill selector using `FlowLayout` for `PCOSFocusArea.allCases`, styled with `Color.nnTint` when selected and `Color(.secondarySystemBackground)` when unselected.
    - Suggestion style segmented picker with descriptions for Gentle Additions vs Direct Swaps.
- Update `NomNom/Auth/AccountView.swift`:
  - Add "Health & Dietary Lenses" section.
  - Embed PCOS settings controls with full interactivity and real-time persistence/syncing.
  - On task appear, sync profile settings from Supabase if logged in.
- Update `NomNom/App/NomNomApp.swift` to provide `PCOSSettingsStore.shared` in the environment.

### Task 5: Build Gate & Testing
- Run `xcodegen generate` and `xcodebuild` for iOS Simulator.
- Ensure `** BUILD SUCCEEDED **`.
- Verify all acceptance criteria are met.
