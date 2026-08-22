import Foundation

/// Mirrors the `households` table (see SPEC.md §1).
struct Household: Identifiable, Codable, Hashable {
    let id: UUID
    var inviteCode: String
    var name: String?
    var requireApproval: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case inviteCode = "invite_code"
        case name
        case requireApproval = "require_approval"
    }

    init(id: UUID, inviteCode: String, name: String? = nil, requireApproval: Bool = false) {
        self.id = id
        self.inviteCode = inviteCode
        self.name = name
        self.requireApproval = requireApproval
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.inviteCode = try container.decode(String.self, forKey: .inviteCode)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.requireApproval = try container.decodeIfPresent(Bool.self, forKey: .requireApproval) ?? false
    }
}
