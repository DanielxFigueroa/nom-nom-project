import Foundation

/// Mirrors the `recipes` table (see SPEC.md §1). Ingredients are populated when
/// fetched via the `select("*, ingredients(*)")` join.
struct Recipe: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var description: String?
    var instructions: String?
    var imageURL: String?
    var householdId: UUID
    var isFavorite: Bool
    var insulinIndexNotes: String?
    var mealTimingSuggestions: String?
    /// Kept as the raw ISO8601 string from Postgres. Ordering is done server-side,
    /// so we avoid client-side date decoding. Parse on demand if displayed.
    var createdAt: String?
    var ingredients: [Ingredient]?

    enum CodingKeys: String, CodingKey {
        case id, title, description, instructions, ingredients
        case imageURL = "image_url"
        case householdId = "household_id"
        case isFavorite = "is_favorite"
        case insulinIndexNotes = "insulin_index_notes"
        case mealTimingSuggestions = "meal_timing_suggestions"
        case createdAt = "created_at"
    }
}
