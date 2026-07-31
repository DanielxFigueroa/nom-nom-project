import Foundation
import Observation

/// Drives the recipe detail screen. Ports RN `app/modal.tsx`.
@MainActor
@Observable
final class RecipeDetailModel {
    var recipe: Recipe
    var ingredients: [Ingredient] = []
    var checkedIDs: Set<UUID> = []
    var isFavorite: Bool
    var isLoading = true

    private let repository = RecipesRepository()

    init(recipe: Recipe) {
        self.recipe = recipe
        self.isFavorite = recipe.isFavorite
        self.ingredients = recipe.ingredients ?? []
    }

    var hasPCOSGuidance: Bool {
        !(recipe.insulinIndexNotes ?? "").isEmpty || !(recipe.mealTimingSuggestions ?? "").isEmpty
    }

    /// Fetches the full recipe + ingredients (the list may pass a lightweight row).
    func load() async {
        do {
            async let recipeTask = repository.fetchRecipe(id: recipe.id)
            async let ingredientsTask = repository.fetchIngredients(recipeID: recipe.id)
            let (fetched, fetchedIngredients) = try await (recipeTask, ingredientsTask)
            recipe = fetched
            isFavorite = fetched.isFavorite
            ingredients = fetchedIngredients
        } catch {
            // Keep whatever we already have from the list row.
        }
        isLoading = false
    }

    func toggleChecked(_ id: UUID) {
        if checkedIDs.contains(id) {
            checkedIDs.remove(id)
        } else {
            checkedIDs.insert(id)
        }
    }

    func toggleFavorite() async {
        isFavorite.toggle()
        do {
            try await repository.setFavorite(recipeID: recipe.id, isFavorite: isFavorite)
        } catch {
            isFavorite.toggle() // revert on failure
        }
    }
}
