import Foundation
import Observation

/// Drives the recipe detail screen. Ports RN `app/modal.tsx`.
@MainActor
@Observable
final class RecipeDetailModel {
    var recipe: Recipe
    var ingredients: [Ingredient] = []
    var tags: [Tag] = []
    var checkedIDs: Set<UUID> = []
    var isFavorite: Bool
    var isLoading = true
    var desiredServings: Int

    private let repository = RecipesRepository()
    private let tagsRepository = TagsRepository()

    init(recipe: Recipe) {
        self.recipe = recipe
        self.isFavorite = recipe.isFavorite
        self.ingredients = recipe.ingredients ?? []
        self.desiredServings = max(recipe.servings, 1)
    }

    var scaleFactor: Double {
        Double(desiredServings) / Double(max(recipe.servings, 1))
    }

    var isServingScaled: Bool {
        desiredServings != recipe.servings
    }

    var hasLegacyUnscalableIngredients: Bool {
        ingredients.contains { $0.quantityValue == nil && !($0.quantity ?? "").isEmpty }
    }

    func formattedLabel(for ingredient: Ingredient) -> String {
        if let val = ingredient.quantityValue {
            let scaledVal = val * scaleFactor
            let qtyStr = FractionFormatter.format(scaledVal)
            return [qtyStr, ingredient.unit, ingredient.name]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
                .joined(separator: " ")
        } else {
            return [ingredient.quantity, ingredient.unit, ingredient.name]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
                .joined(separator: " ")
        }
    }

    func resetServings() {
        desiredServings = max(recipe.servings, 1)
    }

    /// Whether the recipe has the reserved PCOS tag.
    var hasPCOSTag: Bool {
        tags.contains { $0.isPCOS }
    }

    /// Fetches the full recipe + ingredients + tags (the list may pass a lightweight row).
    func load() async {
        do {
            async let recipeTask = repository.fetchRecipe(id: recipe.id)
            async let ingredientsTask = repository.fetchIngredients(recipeID: recipe.id)
            async let tagsTask = tagsRepository.fetchRecipeTags(recipeID: recipe.id)
            let (fetched, fetchedIngredients, fetchedTags) = try await (recipeTask, ingredientsTask, tagsTask)
            let wasAtBaseServings = (desiredServings == max(recipe.servings, 1))
            recipe = fetched
            isFavorite = fetched.isFavorite
            ingredients = fetchedIngredients
            tags = fetchedTags
            if wasAtBaseServings {
                desiredServings = max(fetched.servings, 1)
            }
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
