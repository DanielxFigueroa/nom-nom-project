import SwiftUI

/// Auth-gated root routing (mirrors RN `app/_layout.tsx`, see SPEC.md §3):
/// no session → Login; session but no household → Household Setup; otherwise → tabs.
struct RootView: View {
    @Environment(AuthModel.self) private var auth

    var body: some View {
        Group {
            if auth.isLoading {
                ProgressView()
            } else if !auth.isAuthenticated {
                LoginView()
            } else if auth.householdId == nil {
                HouseholdSetupView()
            } else {
                MainTabView()
            }
        }
    }
}
