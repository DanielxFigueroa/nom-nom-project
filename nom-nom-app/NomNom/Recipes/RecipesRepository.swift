import Foundation
import Supabase

/// Form payload for creating/updating a recipe.
struct RecipeInput {
    var title: String
    var description: String
    var instructions: String
    var imageURL: String
    var insulinIndexNotes: String?
    var mealTimingSuggestions: String?
    var measurementSystem: MeasurementSystem = .imperial
    var servings: Int = 4
    var tagIDs: [UUID] = []
    var folderID: UUID? = nil
}

struct IngredientInput {
    var name: String
    var quantity: String?
    var unit: String?
    var quantityValue: Double? = nil
}

/// Data access for recipes/ingredients (see SPEC.md §1, §5). Mirrors the Supabase
/// calls in the RN app across Explore, detail, add, and edit.
struct RecipesRepository {
    private let client = SupabaseManager.shared

    // MARK: - Fetch

    /// Household-scoped recipes with joined ingredients and tags, newest first.
    func fetchRecipes(householdID: UUID, onlyFavorites: Bool = false) async throws -> [Recipe] {
        var query = client
            .from("recipes")
            .select("*, ingredients(*), tags(*)")
            .eq("household_id", value: householdID)
        if onlyFavorites {
            query = query.eq("is_favorite", value: true)
        }
        return try await query
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func fetchRecipe(id: UUID) async throws -> Recipe {
        try await client
            .from("recipes")
            .select("*")
            .eq("id", value: id)
            .single()
            .execute()
            .value
    }

    func fetchIngredients(recipeID: UUID) async throws -> [Ingredient] {
        try await client
            .from("ingredients")
            .select("*")
            .eq("recipe_id", value: recipeID)
            .execute()
            .value
    }

    // MARK: - Favorite

    private struct ToggleFavoriteParams: Encodable {
        let recipe_id_param: UUID
        let is_fav_param: Bool
    }

    /// Sets favorite via the `toggle_recipe_favorite` RPC, falling back to a
    /// direct update if the RPC errors (matches RN behavior).
    func setFavorite(recipeID: UUID, isFavorite: Bool) async throws {
        do {
            try await client
                .rpc("toggle_recipe_favorite",
                     params: ToggleFavoriteParams(recipe_id_param: recipeID, is_fav_param: isFavorite))
                .execute()
        } catch {
            try await client
                .from("recipes")
                .update(["is_favorite": isFavorite])
                .eq("id", value: recipeID)
                .execute()
        }
    }

    // MARK: - Create / Update / Delete

    private struct RecipeInsert: Encodable {
        let title: String
        let description: String
        let instructions: String
        let image_url: String
        let insulin_index_notes: String?
        let meal_timing_suggestions: String?
        let household_id: UUID
        let measurement_system: String
        let servings: Int
        let folder_id: UUID?
    }

    private struct RecipeUpdate: Encodable {
        let title: String
        let description: String
        let instructions: String
        let image_url: String
        let insulin_index_notes: String?
        let meal_timing_suggestions: String?
        let measurement_system: String
        let servings: Int
        let folder_id: UUID?
    }

    private struct IngredientInsert: Encodable {
        let recipe_id: UUID
        let name: String
        let quantity: String?
        let unit: String?
        let quantity_value: Double?
    }

    private struct IDRow: Decodable { let id: UUID }

    private let tagsRepository = TagsRepository()

    @discardableResult
    func createRecipe(_ input: RecipeInput, ingredients: [IngredientInput], householdID: UUID) async throws -> UUID {
        let row = RecipeInsert(
            title: input.title,
            description: input.description,
            instructions: input.instructions,
            image_url: input.imageURL,
            insulin_index_notes: input.insulinIndexNotes,
            meal_timing_suggestions: input.mealTimingSuggestions,
            household_id: householdID,
            measurement_system: input.measurementSystem.rawValue,
            servings: input.servings,
            folder_id: input.folderID
        )
        let created: IDRow = try await client
            .from("recipes")
            .insert(row)
            .select("id")
            .single()
            .execute()
            .value
        try await insertIngredients(ingredients, recipeID: created.id)
        if !input.tagIDs.isEmpty {
            try await tagsRepository.setRecipeTags(recipeID: created.id, tagIDs: input.tagIDs)
        }
        return created.id
    }

    func updateRecipe(id: UUID, input: RecipeInput, ingredients: [IngredientInput]) async throws {
        let row = RecipeUpdate(
            title: input.title,
            description: input.description,
            instructions: input.instructions,
            image_url: input.imageURL,
            insulin_index_notes: input.insulinIndexNotes,
            meal_timing_suggestions: input.mealTimingSuggestions,
            measurement_system: input.measurementSystem.rawValue,
            servings: input.servings,
            folder_id: input.folderID
        )
        try await client.from("recipes").update(row).eq("id", value: id).execute()
        // Replace ingredient rows: delete existing, then insert the new set.
        try await client.from("ingredients").delete().eq("recipe_id", value: id).execute()
        try await insertIngredients(ingredients, recipeID: id)
        // Replace tag associations.
        try await tagsRepository.setRecipeTags(recipeID: id, tagIDs: input.tagIDs)
    }

    func deleteRecipe(id: UUID) async throws {
        try await client.from("ingredients").delete().eq("recipe_id", value: id).execute()
        try await client.from("recipes").delete().eq("id", value: id).execute()
    }

    private func insertIngredients(_ ingredients: [IngredientInput], recipeID: UUID) async throws {
        guard !ingredients.isEmpty else { return }
        let rows = ingredients.map {
            IngredientInsert(recipe_id: recipeID, name: $0.name, quantity: $0.quantity, unit: $0.unit, quantity_value: $0.quantityValue)
        }
        try await client.from("ingredients").insert(rows).execute()
    }
}
