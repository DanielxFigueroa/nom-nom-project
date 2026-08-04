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

/// Drives the Explore screen: loads household recipes and tags, applies client-side
/// search, tag filtering, and sorting.
@MainActor
@Observable
final class ExploreModel {
    var recipes: [Recipe] = []
    var availableTags: [Tag] = []
    var searchQuery = ""
    var sort: RecipeSort = .newest
    var selectedTagIDs: Set<UUID> = []
    var isLoading = true
    var errorMessage: String?

    private let repository = RecipesRepository()
    private let tagsRepository = TagsRepository()

    var filteredRecipes: [Recipe] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        let filtered = recipes.filter { recipe in
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

            return true
        }

        // 3. Sort
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

    func load(householdID: UUID?) async {
        guard let householdID else {
            isLoading = false
            return
        }
        errorMessage = nil
        do {
            async let recipesTask = repository.fetchRecipes(householdID: householdID)
            async let tagsTask = tagsRepository.fetchTags(householdID: householdID)
            let (fetchedRecipes, fetchedTags) = try await (recipesTask, tagsTask)
            recipes = fetchedRecipes
            availableTags = fetchedTags
        } catch {
            errorMessage = describeError(error)
        }
        isLoading = false
    }

    func toggleTagSelection(_ tagID: UUID) {
        if selectedTagIDs.contains(tagID) {
            selectedTagIDs.remove(tagID)
        } else {
            selectedTagIDs.insert(tagID)
        }
    }
}

