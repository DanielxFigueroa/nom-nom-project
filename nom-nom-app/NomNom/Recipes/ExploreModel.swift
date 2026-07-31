import Foundation
import Observation

/// Drives the Explore screen: loads household recipes and applies client-side
/// search by title OR ingredient name (ports RN `RecipeList` filtering).
@MainActor
@Observable
final class ExploreModel {
    var recipes: [Recipe] = []
    var searchQuery = ""
    var isLoading = true
    var errorMessage: String?

    private let repository = RecipesRepository()

    var filteredRecipes: [Recipe] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return recipes }
        return recipes.filter { recipe in
            let matchesTitle = recipe.title.lowercased().contains(query)
            let matchesIngredient = (recipe.ingredients ?? []).contains {
                $0.name.lowercased().contains(query)
            }
            return matchesTitle || matchesIngredient
        }
    }

    func load(householdID: UUID?) async {
        guard let householdID else {
            isLoading = false
            return
        }
        errorMessage = nil
        do {
            recipes = try await repository.fetchRecipes(householdID: householdID)
        } catch {
            errorMessage = describeError(error)
        }
        isLoading = false
    }
}
