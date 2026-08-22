import Foundation

enum HouseholdMemberStatus: String, Codable, Hashable {
    case pending
    case active
    case declined
}

enum HouseholdMemberRole: String, Codable, Hashable {
    case owner
    case member
}

/// Represents a row in the `household_members` join table.
struct HouseholdMember: Identifiable, Codable, Hashable {
    let userId: UUID
    let householdId: UUID
    let joinedAt: String?
    let status: HouseholdMemberStatus?
    let role: HouseholdMemberRole?

    var id: UUID { householdId }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case householdId = "household_id"
        case joinedAt = "joined_at"
        case status
        case role
    }
}
