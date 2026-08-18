import Foundation

/// Represents a row in the `household_members` join table.
struct HouseholdMember: Identifiable, Codable, Hashable {
    let userId: UUID
    let householdId: UUID
    let joinedAt: String?
    var id: UUID { householdId }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case householdId = "household_id"
        case joinedAt = "joined_at"
    }
}
