import Foundation
import Observation

/// Loads the household's favorite recipes (ports RN `RecipeList` with `onlyFavorites`).
@MainActor
@Observable
final class FavoritesModel {
    var recipes: [Recipe] = []
    var isLoading = true

    private let repository = RecipesRepository()

    func load(householdIDs: [UUID]) async {
        guard !householdIDs.isEmpty else {
            isLoading = false
            return
        }
        do {
            recipes = try await repository.fetchRecipes(householdIDs: householdIDs, onlyFavorites: true)
        } catch {
            // Keep existing on failure.
        }
        isLoading = false
    }

    func load(householdID: UUID?) async {
        await load(householdIDs: householdID.map { [$0] } ?? [])
    }
}
