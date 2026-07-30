import Foundation

/// Mirrors the `profiles` table (see SPEC.md §1). `id` equals the auth user id.
struct Profile: Identifiable, Codable, Hashable {
    let id: UUID
    var householdId: UUID?

    enum CodingKeys: String, CodingKey {
        case id
        case householdId = "household_id"
    }
}
