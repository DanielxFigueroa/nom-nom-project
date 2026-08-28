import SwiftUI

/// The three-tab main app (mirrors RN `(tabs)/_layout.tsx`, see SPEC.md §3).
struct MainTabView: View {
    @Environment(AuthModel.self) private var auth

    var body: some View {
        TabView {
            ExploreView()
                .tabItem { Label("Explore", systemImage: "square.grid.2x2") }

            FavoritesView()
                .tabItem { Label("Favorites", systemImage: "heart") }

            AddRecipeView()
                .tabItem { Label("Add", systemImage: "plus.circle") }

            HouseholdsView()
                .tabItem { Label("Households", systemImage: "house") }
                .badge(auth.totalPendingCount)
        }
        .tint(.nnTint)
    }
}
