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
    var tags: [Tag]?
    var measurementSystem: MeasurementSystem
    var servings: Int

    enum CodingKeys: String, CodingKey {
        case id, title, description, instructions, ingredients, tags, servings
        case imageURL = "image_url"
        case householdId = "household_id"
        case isFavorite = "is_favorite"
        case insulinIndexNotes = "insulin_index_notes"
        case mealTimingSuggestions = "meal_timing_suggestions"
        case createdAt = "created_at"
        case measurementSystem = "measurement_system"
    }

    init(
        id: UUID,
        title: String,
        description: String? = nil,
        instructions: String? = nil,
        imageURL: String? = nil,
        householdId: UUID,
        isFavorite: Bool = false,
        insulinIndexNotes: String? = nil,
        mealTimingSuggestions: String? = nil,
        createdAt: String? = nil,
        ingredients: [Ingredient]? = nil,
        tags: [Tag]? = nil,
        measurementSystem: MeasurementSystem = .imperial,
        servings: Int = 4
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.instructions = instructions
        self.imageURL = imageURL
        self.householdId = householdId
        self.isFavorite = isFavorite
        self.insulinIndexNotes = insulinIndexNotes
        self.mealTimingSuggestions = mealTimingSuggestions
        self.createdAt = createdAt
        self.ingredients = ingredients
        self.tags = tags
        self.measurementSystem = measurementSystem
        self.servings = servings
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        instructions = try container.decodeIfPresent(String.self, forKey: .instructions)
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        householdId = try container.decode(UUID.self, forKey: .householdId)
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        insulinIndexNotes = try container.decodeIfPresent(String.self, forKey: .insulinIndexNotes)
        mealTimingSuggestions = try container.decodeIfPresent(String.self, forKey: .mealTimingSuggestions)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        ingredients = try container.decodeIfPresent([Ingredient].self, forKey: .ingredients)
        tags = try container.decodeIfPresent([Tag].self, forKey: .tags)
        measurementSystem = try container.decodeIfPresent(MeasurementSystem.self, forKey: .measurementSystem) ?? .imperial
        servings = try container.decodeIfPresent(Int.self, forKey: .servings) ?? 4
    }
}


