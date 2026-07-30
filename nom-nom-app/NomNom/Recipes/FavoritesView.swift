import SwiftUI

/// Favorites: same grid filtered to is_favorite (SPEC.md §4). Implemented in Milestone 2.
struct FavoritesView: View {
    var body: some View {
        NavigationStack {
            ScaffoldPlaceholder(
                title: "Favorites",
                specNote: "Milestone 2: recipe grid filtered to is_favorite == true; empty state when none."
            )
            .navigationTitle("Favorites")
        }
    }
}
