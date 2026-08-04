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
                if !model.availableTags.isEmpty {
                    tagChipStrip
                }
                content
            }
            .navigationTitle("Explore")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Menu {
                            Picker("Sort", selection: $model.sort) {
                                ForEach(RecipeSort.allCases) { option in
                                    Text(option.displayName).tag(option)
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                        }
                        .accessibilityLabel("Sort")

                        Button {
                            showAccount = true
                        } label: {
                            Image(systemName: "person.crop.circle")
                        }
                        .accessibilityLabel("Account")
                    }
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

    private var tagChipStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(model.availableTags) { tag in
                    let isSelected = model.selectedTagIDs.contains(tag.id)
                    Button {
                        model.toggleTagSelection(tag.id)
                    } label: {
                        HStack(spacing: 4) {
                            if tag.isPCOS {
                                Image(systemName: "sparkles")
                                    .font(.caption2)
                            }
                            Text(tag.name)
                                .font(.subheadline)
                                .fontWeight(isSelected ? .semibold : .regular)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            isSelected
                            ? (tag.isPCOS ? Color.nnTint : Color.accentColor)
                            : Color(.secondarySystemBackground)
                        )
                        .foregroundColor(isSelected ? .white : .primary)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
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
            if !model.searchQuery.isEmpty {
                ContentUnavailableView.search(text: model.searchQuery)
            } else {
                ContentUnavailableView(
                    "No Matching Recipes",
                    systemImage: "line.3.horizontal.decrease.circle",
                    description: Text("Try clearing your tag filters or changing your search terms.")
                )
            }
        } else {
            RecipeMasonry(recipes: model.filteredRecipes)
                .refreshable { await model.load(householdID: auth.householdId) }
        }
    }
}

