import Foundation

/// Mirrors the `tags` table. Tags are household-scoped with an optional
/// reserved `is_pcos` flag for the PCOS toggle-tag.
struct Tag: Identifiable, Codable, Hashable {
    let id: UUID
    var householdId: UUID
    var name: String
    var isPCOS: Bool
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case householdId = "household_id"
        case isPCOS = "is_pcos"
        case createdAt = "created_at"
    }

    init(id: UUID = UUID(), householdId: UUID, name: String, isPCOS: Bool = false, createdAt: String? = nil) {
        self.id = id
        self.householdId = householdId
        self.name = name
        self.isPCOS = isPCOS
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        householdId = try container.decode(UUID.self, forKey: .householdId)
        name = try container.decode(String.self, forKey: .name)
        isPCOS = try container.decodeIfPresent(Bool.self, forKey: .isPCOS) ?? false
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
    }
}
