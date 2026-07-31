import SwiftUI

/// Explore: search bar + 2-column recipe grid (SPEC.md §4). Ports RN
/// `(tabs)/index.tsx` + `RecipeList`.
struct ExploreView: View {
    @Environment(AuthModel.self) private var auth
    @Environment(RecipesRefresh.self) private var recipesRefresh
    @State private var model = ExploreModel()
    @State private var showAccount = false

    var body: some View {
        @Bindable var model = model

        NavigationStack {
            VStack(spacing: 8) {
                SearchBar(text: $model.searchQuery)
                content
            }
            .navigationTitle("Explore")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAccount = true
                    } label: {
                        Image(systemName: "person.crop.circle")
                    }
                    .accessibilityLabel("Account")
                }
            }
            .sheet(isPresented: $showAccount) {
                AccountView()
            }
        }
        .onAppear { Task { await model.load(householdID: auth.householdId) } }
        .onChange(of: recipesRefresh.token) {
            Task { await model.load(householdID: auth.householdId) }
        }
    }

    @ViewBuilder
    private var content: some View {
        if model.isLoading {
            Spacer()
            ProgressView()
            Spacer()
        } else if let errorMessage = model.errorMessage {
            ContentUnavailableView {
                Label("Couldn't load recipes", systemImage: "exclamationmark.triangle")
            } description: {
                Text(errorMessage)
            } actions: {
                Button("Retry") { Task { await model.load(householdID: auth.householdId) } }
            }
        } else if model.recipes.isEmpty {
            ContentUnavailableView(
                "No recipes found in your household.",
                systemImage: "fork.knife"
            )
        } else if model.filteredRecipes.isEmpty {
            ContentUnavailableView.search(text: model.searchQuery)
        } else {
            RecipeMasonry(recipes: model.filteredRecipes)
                .refreshable { await model.load(householdID: auth.householdId) }
        }
    }
}
