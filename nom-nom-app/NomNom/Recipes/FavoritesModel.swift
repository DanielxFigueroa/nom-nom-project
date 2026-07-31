import Foundation
import Observation

/// Loads the household's favorite recipes (ports RN `RecipeList` with `onlyFavorites`).
@MainActor
@Observable
final class FavoritesModel {
    var recipes: [Recipe] = []
    var isLoading = true

    private let repository = RecipesRepository()

    func load(householdID: UUID?) async {
        guard let householdID else {
            isLoading = false
            return
        }
        do {
            recipes = try await repository.fetchRecipes(householdID: householdID, onlyFavorites: true)
        } catch {
            // Keep existing on failure.
        }
        isLoading = false
    }
}
