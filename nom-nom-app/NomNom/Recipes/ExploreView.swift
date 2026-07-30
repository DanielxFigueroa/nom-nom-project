import SwiftUI

/// Explore: search bar + 2-column recipe grid (SPEC.md §4). Implemented in Milestone 1.
struct ExploreView: View {
    var body: some View {
        NavigationStack {
            ScaffoldPlaceholder(
                title: "Explore",
                specNote: "Milestone 1: RecipesRepository.fetchRecipes; 2-column grid; client-side search by title OR ingredient name."
            )
            .navigationTitle("Explore")
        }
    }
}
