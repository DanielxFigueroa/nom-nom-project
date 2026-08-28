import Foundation

/// Mirrors the `folders` table. Folders are household-scoped with an optional `parentId` for nesting.
struct Folder: Identifiable, Codable, Hashable {
    let id: UUID
    var householdId: UUID
    var name: String
    var parentId: UUID?
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case householdId = "household_id"
        case parentId = "parent_id"
        case createdAt = "created_at"
    }

    init(id: UUID = UUID(), householdId: UUID, name: String, parentId: UUID? = nil, createdAt: String? = nil) {
        self.id = id
        self.householdId = householdId
        self.name = name
        self.parentId = parentId
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        householdId = try container.decode(UUID.self, forKey: .householdId)
        name = try container.decode(String.self, forKey: .name)
        parentId = try container.decodeIfPresent(UUID.self, forKey: .parentId)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
    }
}
