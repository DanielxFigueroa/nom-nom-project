import Foundation
import Supabase

/// Data access for recipes/ingredients (see SPEC.md §1, §5). One method per
/// Supabase operation the app performs. Milestone 1 uses `fetchRecipes`; the
/// remaining CRUD methods are filled in during Milestone 2.
struct RecipesRepository {
    private let client = SupabaseManager.shared

    /// Explore/Favorites feed: household-scoped recipes with joined ingredients.
    func fetchRecipes(householdID: UUID) async throws -> [Recipe] {
        try await client
            .from("recipes")
            .select("*, ingredients(*)")
            .eq("household_id", value: householdID)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    // Milestone 2 (see SPEC.md §4):
    // - func fetchRecipe(id:) async throws -> Recipe
    // - func createRecipe(...) / updateRecipe(...) / deleteRecipe(id:)
    // - func setFavorite(recipeID:isFavorite:) — rpc("toggle_recipe_favorite") w/ update fallback
    // - ingredient replace (delete by recipe_id, then insert)
}
