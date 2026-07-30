import Foundation

/// Mirrors the `households` table (see SPEC.md §1).
struct Household: Identifiable, Codable, Hashable {
    let id: UUID
    var inviteCode: String

    enum CodingKeys: String, CodingKey {
        case id
        case inviteCode = "invite_code"
    }
}
