import Foundation

/// Mirrors the `ingredients` table (see SPEC.md §1).
struct Ingredient: Identifiable, Codable, Hashable {
    let id: UUID
    var recipeId: UUID
    var name: String
    var quantity: String?
    var unit: String?

    enum CodingKeys: String, CodingKey {
        case id, name, quantity, unit
        case recipeId = "recipe_id"
    }
}
