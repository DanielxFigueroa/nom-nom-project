import SwiftUI

/// Favorites: recipe grid filtered to is_favorite (SPEC.md §4). Reloads on appear
/// so favorites toggled elsewhere stay in sync.
struct FavoritesView: View {
    @Environment(AuthModel.self) private var auth
    @Environment(RecipesRefresh.self) private var recipesRefresh
    @State private var model = FavoritesModel()

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Favorites")
        }
        .task {
            await model.load(householdIDs: auth.joinedHouseholdIds)
        }
        .onChange(of: auth.joinedHouseholdIds) {
            Task { await model.load(householdIDs: auth.joinedHouseholdIds) }
        }
        .onChange(of: recipesRefresh.token) {
            Task { await model.load(householdIDs: auth.joinedHouseholdIds) }
        }
    }

    @ViewBuilder
    private var content: some View {
        if model.isLoading {
            ProgressView()
        } else if model.recipes.isEmpty {
            ContentUnavailableView(
                "No favorite recipes yet",
                systemImage: "heart",
                description: Text("Bookmark recipes to view them here!")
            )
        } else {
            RecipeMasonry(recipes: model.recipes)
                .refreshable { await model.load(householdIDs: auth.joinedHouseholdIds) }
        }
    }
}
