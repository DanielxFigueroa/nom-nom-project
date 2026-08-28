import SwiftUI

/// Explore: search bar + Collectr-style pill filter bar + recipe grid (SPEC.md §4). Ports RN
/// `(tabs)/index.tsx` + `RecipeList`.
struct ExploreView: View {
    @Environment(AuthModel.self) private var auth
    @Environment(RecipesRefresh.self) private var recipesRefresh
    @State private var model = ExploreModel()
    @State private var showAccount = false
    @State private var showFolders = false

    var body: some View {
        @Bindable var model = model

        NavigationStack {
            VStack(spacing: 8) {
                SearchBar(text: $model.searchQuery)
                if auth.joinedHouseholds.count > 1 {
                    householdPillBar
                }
                PillFilterBar(model: model)
                if model.selectedFolderID != nil {
                    folderBreadcrumbBar
                }
                content
            }
            .navigationTitle("Explore")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            showFolders = true
                        } label: {
                            Image(systemName: "folder")
                        }
                        .accessibilityLabel("Folders")

                        Button {
                            showAccount = true
                        } label: {
                            Image(systemName: "person.crop.circle")
                        }
                        .accessibilityLabel("Account")
                    }
                }
            }
            .sheet(isPresented: $showFolders) {
                if let householdID = auth.householdId {
                    FolderManagerView(householdID: householdID)
                }
            }
            .sheet(isPresented: $showAccount) {
                AccountView()
            }
        }
        .task {
            await model.load(householdIDs: auth.joinedHouseholdIds, joinedHouseholds: auth.joinedHouseholds)
        }
        .onChange(of: auth.joinedHouseholdIds) {
            Task { await model.load(householdIDs: auth.joinedHouseholdIds, joinedHouseholds: auth.joinedHouseholds) }
        }
        .onChange(of: recipesRefresh.token) {
            Task { await model.load(householdIDs: auth.joinedHouseholdIds, joinedHouseholds: auth.joinedHouseholds) }
        }
    }

    private var householdPillBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(auth.joinedHouseholds) { household in
                    let isSelected = model.selectedHouseholdID == household.id
                    Button {
                        model.selectedHouseholdID = isSelected ? nil : household.id
                    } label: {
                        Label(
                            household.name ?? "Household",
                            systemImage: household.id == auth.householdId ? "house.fill" : "house"
                        )
                        .font(.subheadline.weight(isSelected ? .semibold : .regular))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(isSelected ? Color.nnTint : Color(.secondarySystemBackground))
                        .foregroundStyle(isSelected ? .white : .primary)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }

    private var folderBreadcrumbBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "folder.fill")
                .font(.caption)
                .foregroundColor(.nnTint)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    Button("All") {
                        model.selectedFolderID = nil
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                    ForEach(Array(model.folderBreadcrumbs.enumerated()), id: \.element.id) { index, folder in
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        let isLast = index == model.folderBreadcrumbs.count - 1
                        Button(folder.name) {
                            model.selectedFolderID = folder.id
                        }
                        .font(.subheadline)
                        .fontWeight(isLast ? .bold : .regular)
                        .foregroundColor(isLast ? .primary : .secondary)
                    }
                }
            }

            Spacer()

            Button {
                model.selectedFolderID = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .accessibilityLabel("Clear folder filter")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.secondarySystemBackground).opacity(0.8))
        .cornerRadius(8)
        .padding(.horizontal)
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
                Button("Retry") { Task { await model.load(householdIDs: auth.joinedHouseholdIds, joinedHouseholds: auth.joinedHouseholds) } }
            }
        } else if model.recipes.isEmpty {
            ContentUnavailableView(
                model.selectedHouseholdID != nil ? "No recipes in this household yet." : "No recipes found in your households.",
                systemImage: "fork.knife"
            )
        } else if model.filteredRecipes.isEmpty {
            if !model.searchQuery.isEmpty {
                ContentUnavailableView.search(text: model.searchQuery)
            } else if model.selectedHouseholdID != nil && model.selectedTagIDs.isEmpty && model.selectedFolderID == nil {
                ContentUnavailableView(
                    "No recipes in this household yet.",
                    systemImage: "fork.knife"
                )
            } else {
                ContentUnavailableView(
                    "No Matching Recipes",
                    systemImage: "line.3.horizontal.decrease.circle",
                    description: Text("Try clearing your folder, tag, or household filters, or changing your search terms.")
                )
            }
        } else {
            RecipeMasonry(recipes: model.filteredRecipes)
                .refreshable { await model.load(householdIDs: auth.joinedHouseholdIds, joinedHouseholds: auth.joinedHouseholds) }
        }
    }
}
