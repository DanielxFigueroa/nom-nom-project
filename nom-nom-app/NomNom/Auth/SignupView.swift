import SwiftUI

/// Create account (SPEC.md §4). Implemented in Milestone 1.
struct SignupView: View {
    var body: some View {
        ScaffoldPlaceholder(
            title: "Sign Up",
            specNote: "Milestone 1: email + password → AuthModel.signUp → route to Household Setup."
        )
    }
}
