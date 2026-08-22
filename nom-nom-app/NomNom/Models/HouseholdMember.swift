import Foundation

/// Represents a row in the `household_members` join table.
struct HouseholdMember: Identifiable, Codable, Hashable {
    let userId: UUID
    let householdId: UUID
    let joinedAt: String?
    let status: MemberStatus
    let role: MemberRole

    var id: UUID { householdId }

    enum MemberStatus: String, Codable, Hashable {
        case pending, active, declined
    }

    enum MemberRole: String, Codable, Hashable {
        case owner, member
    }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case householdId = "household_id"
        case joinedAt = "joined_at"
        case status, role
    }

    init(
        userId: UUID,
        householdId: UUID,
        joinedAt: String? = nil,
        status: MemberStatus = .active,
        role: MemberRole = .member
    ) {
        self.userId = userId
        self.householdId = householdId
        self.joinedAt = joinedAt
        self.status = status
        self.role = role
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.userId = try container.decode(UUID.self, forKey: .userId)
        self.householdId = try container.decode(UUID.self, forKey: .householdId)
        self.joinedAt = try container.decodeIfPresent(String.self, forKey: .joinedAt)
        self.status = (try container.decodeIfPresent(MemberStatus.self, forKey: .status)) ?? .active
        self.role = (try container.decodeIfPresent(MemberRole.self, forKey: .role)) ?? .member
    }
}

typealias HouseholdMemberStatus = HouseholdMember.MemberStatus
typealias HouseholdMemberRole = HouseholdMember.MemberRole
