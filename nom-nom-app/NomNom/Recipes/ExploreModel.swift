import Foundation
import Observation

/// Sort options for recipes on Explore.
enum RecipeSort: String, CaseIterable, Identifiable {
    case newest = "Newest"
    case oldest = "Oldest"
    case titleAsc = "Title (A–Z)"
    case titleZ = "Title (Z–A)"
    case favoritesFirst = "Favorites First"

    var id: String { rawValue }
    var displayName: String { rawValue }
}

/// Helper representing a node in the folder hierarchy tree.
struct FolderNode: Identifiable {
    let folder: Folder
    let depth: Int
    var id: UUID { folder.id }
}

/// Drives the Explore screen: loads household recipes, tags, and folders,
/// applying client-side search, tag filtering, folder scoping, and sorting.
@MainActor
@Observable
final class ExploreModel {
    var recipes: [Recipe] = []
    var availableTags: [Tag] = []
    var availableFolders: [Folder] = []
    var joinedHouseholds: [Household] = []
    var searchQuery = ""
    var sort: RecipeSort = .newest
    var selectedTagIDs: Set<UUID> = []
    var selectedFolderID: UUID? = nil
    var selectedHouseholdID: UUID? = nil
    var isLoading = true
    var errorMessage: String?

    private let repository = RecipesRepository()
    private let tagsRepository = TagsRepository()
    private let foldersRepository = FoldersRepository()

    var selectedFolder: Folder? {
        guard let selectedFolderID else { return nil }
        return availableFolders.first { $0.id == selectedFolderID }
    }

    /// Breadcrumb path from top root to current `selectedFolder`.
    var folderBreadcrumbs: [Folder] {
        guard let selectedFolderID else { return [] }
        var crumbs: [Folder] = []
        var current: Folder? = availableFolders.first { $0.id == selectedFolderID }
        while let f = current {
            crumbs.insert(f, at: 0)
            if let parentID = f.parentId {
                current = availableFolders.first { $0.id == parentID }
            } else {
                current = nil
            }
        }
        return crumbs
    }

    /// Set of folder IDs consisting of `folderID` and all its descendant folder IDs.
    func folderAndDescendantIDs(for folderID: UUID) -> Set<UUID> {
        var result: Set<UUID> = [folderID]
        var queue: [UUID] = [folderID]
        while !queue.isEmpty {
            let currentID = queue.removeFirst()
            let children = availableFolders.filter { $0.parentId == currentID }.map { $0.id }
            for childID in children {
                if result.insert(childID).inserted {
                    queue.append(childID)
                }
            }
        }
        return result
    }

    /// Generates a depth-first list of folders with depth levels for indented display.
    func hierarchicalFolders() -> [FolderNode] {
        var nodes: [FolderNode] = []

        func appendChildren(of parentID: UUID?, depth: Int) {
            let children = availableFolders
                .filter { $0.parentId == parentID }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            for child in children {
                nodes.append(FolderNode(folder: child, depth: depth))
                appendChildren(of: child.id, depth: depth + 1)
            }
        }

        appendChildren(of: nil, depth: 0)

        let addedIDs = Set(nodes.map { $0.id })
        let remaining = availableFolders
            .filter { !addedIDs.contains($0.id) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        for folder in remaining {
            nodes.append(FolderNode(folder: folder, depth: 0))
        }

        return nodes
    }

    var filteredRecipes: [Recipe] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let folderScopeIDs: Set<UUID>? = selectedFolderID.map { folderAndDescendantIDs(for: $0) }

        let filtered = recipes.filter { recipe in
            // 0. Household filter
            if let selectedHouseholdID {
                guard recipe.householdId == selectedHouseholdID else { return false }
            }

            // 1. Text search filter
            if !query.isEmpty {
                let matchesTitle = recipe.title.lowercased().contains(query)
                let matchesIngredient = (recipe.ingredients ?? []).contains {
                    $0.name.lowercased().contains(query)
                }
                guard matchesTitle || matchesIngredient else { return false }
            }

            // 2. Tag filter
            if !selectedTagIDs.isEmpty {
                let recipeTagIDs = Set((recipe.tags ?? []).map { $0.id })
                guard selectedTagIDs.isSubset(of: recipeTagIDs) else { return false }
            }

            // 3. Folder scope filter (scopes to selected folder + all subfolders)
            if let folderScopeIDs {
                guard let recipeFolderID = recipe.folderId, folderScopeIDs.contains(recipeFolderID) else {
                    return false
                }
            }

            return true
        }

        // 4. Sort
        switch sort {
        case .newest:
            return filtered.sorted { ($0.createdAt ?? "") > ($1.createdAt ?? "") }
        case .oldest:
            return filtered.sorted { ($0.createdAt ?? "") < ($1.createdAt ?? "") }
        case .titleAsc:
            return filtered.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .titleZ:
            return filtered.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedDescending }
        case .favoritesFirst:
            return filtered.sorted { r1, r2 in
                if r1.isFavorite != r2.isFavorite {
                    return r1.isFavorite && !r2.isFavorite
                }
                return (r1.createdAt ?? "") > (r2.createdAt ?? "")
            }
        }
    }

    func load(householdIDs: [UUID], joinedHouseholds: [Household] = []) async {
        guard !householdIDs.isEmpty else {
            recipes = []
            availableTags = []
            availableFolders = []
            self.joinedHouseholds = joinedHouseholds
            isLoading = false
            return
        }
        errorMessage = nil
        do {
            async let recipesTask = repository.fetchRecipes(householdIDs: householdIDs)
            async let tagsTask = tagsRepository.fetchTags(householdIDs: householdIDs)
            async let foldersTask = foldersRepository.fetchFolders(householdIDs: householdIDs)
            let (fetchedRecipes, fetchedTags, fetchedFolders) = try await (recipesTask, tagsTask, foldersTask)
            recipes = fetchedRecipes
            availableTags = fetchedTags
            availableFolders = fetchedFolders
            self.joinedHouseholds = joinedHouseholds
        } catch {
            errorMessage = describeError(error)
        }
        isLoading = false
    }

    func load(householdID: UUID?) async {
        await load(householdIDs: householdID.map { [$0] } ?? [])
    }

    func toggleTagSelection(_ tagID: UUID) {
        if selectedTagIDs.contains(tagID) {
            selectedTagIDs.remove(tagID)
        } else {
            selectedTagIDs.insert(tagID)
        }
    }

    func clearFilters() {
        searchQuery = ""
        sort = .newest
        selectedTagIDs.removeAll()
        selectedFolderID = nil
        selectedHouseholdID = nil
    }

    var hasActiveFilters: Bool {
        !searchQuery.isEmpty || sort != .newest || !selectedTagIDs.isEmpty || selectedFolderID != nil || selectedHouseholdID != nil
    }
}
