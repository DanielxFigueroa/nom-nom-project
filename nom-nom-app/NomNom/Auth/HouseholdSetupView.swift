import SwiftUI

/// Create (generate 6-char code) or join a household by invite code (SPEC.md §4).
/// Implemented in Milestone 1.
struct HouseholdSetupView: View {
    var body: some View {
        ScaffoldPlaceholder(
            title: "Household Setup",
            specNote: "Milestone 1: Create → insert households + upsert profile; Join → look up by invite_code; then AuthModel.refreshProfile()."
        )
    }
}
