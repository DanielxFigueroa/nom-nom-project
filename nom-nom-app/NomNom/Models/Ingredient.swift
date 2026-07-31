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

    init(id: UUID, recipeId: UUID, name: String, quantity: String?, unit: String?) {
        self.id = id
        self.recipeId = recipeId
        self.name = name
        self.quantity = quantity
        self.unit = unit
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        recipeId = try container.decode(UUID.self, forKey: .recipeId)
        name = try container.decode(String.self, forKey: .name)
        unit = try container.decodeIfPresent(String.self, forKey: .unit)
        // `quantity` may arrive as a String (text column) or a number (numeric
        // column), depending on how the table was defined. Accept both.
        if let string = try? container.decodeIfPresent(String.self, forKey: .quantity) {
            quantity = string
        } else if let number = try? container.decodeIfPresent(Double.self, forKey: .quantity) {
            quantity = number.formatted(.number.grouping(.never))
        } else {
            quantity = nil
        }
    }
}
