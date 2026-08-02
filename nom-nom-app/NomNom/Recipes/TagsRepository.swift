import Foundation
import Supabase

/// Data access for household-scoped tags and recipe-tag associations.
struct TagsRepository {
    private let client = SupabaseManager.shared

    // MARK: - Fetch

    /// All tags for the given household.
    func fetchTags(householdID: UUID) async throws -> [Tag] {
        try await client
            .from("tags")
            .select("*")
            .eq("household_id", value: householdID)
            .order("name")
            .execute()
            .value
    }

    /// Tags associated with a specific recipe (via the recipe_tags junction).
    func fetchRecipeTags(recipeID: UUID) async throws -> [Tag] {
        // Use the PostgREST resource-embedding syntax to join through recipe_tags.
        let rows: [RecipeTagJoin] = try await client
            .from("recipe_tags")
            .select("tag_id, tags(*)")
            .eq("recipe_id", value: recipeID)
            .execute()
            .value
        return rows.compactMap { $0.tags }
    }

    // MARK: - Create

    private struct TagInsert: Encodable {
        let household_id: UUID
        let name: String
        let is_pcos: Bool
    }

    /// Creates a new tag in the household.
    @discardableResult
    func createTag(name: String, householdID: UUID, isPCOS: Bool = false) async throws -> Tag {
        try await client
            .from("tags")
            .insert(TagInsert(household_id: householdID, name: name, is_pcos: isPCOS))
            .select("*")
            .single()
            .execute()
            .value
    }

    /// Ensures the reserved PCOS tag exists for the household. Returns the tag
    /// whether it already existed or was just created.
    @discardableResult
    func ensurePCOSTag(householdID: UUID) async throws -> Tag {
        // Check if it already exists.
        let existing: [Tag] = try await client
            .from("tags")
            .select("*")
            .eq("household_id", value: householdID)
            .eq("is_pcos", value: true)
            .limit(1)
            .execute()
            .value
        if let tag = existing.first {
            return tag
        }
        return try await createTag(name: "PCOS", householdID: householdID, isPCOS: true)
    }

    // MARK: - Set recipe tags

    private struct RecipeTagInsert: Encodable {
        let recipe_id: UUID
        let tag_id: UUID
    }

    /// Replaces all tags on a recipe with the given set of tag IDs.
    func setRecipeTags(recipeID: UUID, tagIDs: [UUID]) async throws {
        // Delete existing associations for this recipe.
        try await client
            .from("recipe_tags")
            .delete()
            .eq("recipe_id", value: recipeID)
            .execute()
        // Insert new associations.
        guard !tagIDs.isEmpty else { return }
        let rows = tagIDs.map { RecipeTagInsert(recipe_id: recipeID, tag_id: $0) }
        try await client
            .from("recipe_tags")
            .insert(rows)
            .execute()
    }

    // MARK: - Private join model

    /// Intermediate model for decoding the recipe_tags → tags join.
    private struct RecipeTagJoin: Decodable {
        let tags: Tag?
    }
}
