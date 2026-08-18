import Foundation
import Supabase

/// Data access for household create/join + profile linking.
/// Ports the Supabase calls in RN `app/(auth)/household-setup.tsx`.
struct HouseholdRepository {
    private let client = SupabaseManager.shared

    // MARK: - Join Models for PostgREST

    private struct HouseholdMemberJoin: Decodable {
        let households: Household?
    }

    private struct HouseholdMemberInsert: Encodable {
        let user_id: UUID
        let household_id: UUID
    }

    // MARK: - Multi-Household Methods

    /// Query `household_members` joined to `households` to get all households for the user.
    func fetchJoinedHouseholds(userID: UUID) async throws -> [Household] {
        let rows: [HouseholdMemberJoin] = try await client
            .from("household_members")
            .select("household_id, households(*)")
            .eq("user_id", value: userID)
            .execute()
            .value
        return rows.compactMap { $0.households }
    }

    /// INSERT INTO `household_members(user_id, household_id)` ON CONFLICT DO NOTHING.
    func joinHousehold(userID: UUID, householdID: UUID) async throws {
        let member = HouseholdMemberInsert(user_id: userID, household_id: householdID)
        try await client
            .from("household_members")
            .upsert(member, ignoreDuplicates: true)
            .execute()
    }

    /// Fetch a single household by ID (needed to display the owned household's invite code).
    func fetchHousehold(id: UUID) async throws -> Household? {
        try await client
            .from("households")
            .select("*")
            .eq("id", value: id)
            .maybeSingle()
            .execute()
            .value
    }

    // MARK: - Setup / Link Methods

    /// Creates a new household with a random invite code and optional name; returns its id.
    /// Also inserts into `household_members` if `userID` is provided.
    func createHousehold(name: String? = nil, userID: UUID? = nil) async throws -> UUID {
        var payload: [String: String] = ["invite_code": InviteCode.generate()]
        if let trimmed = name?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty {
            payload["name"] = trimmed
        }
        let household: Household = try await client
            .from("households")
            .insert(payload)
            .select()
            .single()
            .execute()
            .value

        if let userID = userID {
            try await joinHousehold(userID: userID, householdID: household.id)
        }
        return household.id
    }

    /// Looks up a household id by invite code (case-insensitive). nil if not found.
    /// Also calls `joinHousehold` if `userID` is provided and a household is found.
    func findHousehold(inviteCode: String, userID: UUID? = nil) async throws -> UUID? {
        let household: Household? = try await client
            .from("households")
            .select("id, invite_code, name")
            .eq("invite_code", value: inviteCode.uppercased())
            .maybeSingle()
            .execute()
            .value

        if let householdID = household?.id, let userID = userID {
            try await joinHousehold(userID: userID, householdID: householdID)
        }
        return household?.id
    }

    /// Upserts the user's profile row with the household id (works even when no
    /// profile row exists yet), matching the RN upsert behavior.
    /// Also inserts into `household_members`.
    func linkProfile(userID: UUID, householdID: UUID) async throws {
        try await client
            .from("profiles")
            .upsert(Profile(id: userID, householdId: householdID))
            .execute()

        try await joinHousehold(userID: userID, householdID: householdID)
    }
}
