import Foundation
import Supabase

/// Data access for household create/join + profile linking.
/// Ports the Supabase calls in RN `app/(auth)/household-setup.tsx`.
struct HouseholdRepository {
    private let client = SupabaseManager.shared

    /// Creates a new household with a random invite code and optional name; returns its id.
    func createHousehold(name: String? = nil) async throws -> UUID {
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
        return household.id
    }

    /// Looks up a household id by invite code (case-insensitive). nil if not found.
    func findHousehold(inviteCode: String) async throws -> UUID? {
        let household: Household? = try await client
            .from("households")
            .select("id, invite_code")
            .eq("invite_code", value: inviteCode.uppercased())
            .maybeSingle()
            .execute()
            .value
        return household?.id
    }

    /// Upserts the user's profile row with the household id (works even when no
    /// profile row exists yet), matching the RN upsert behavior.
    func linkProfile(userID: UUID, householdID: UUID) async throws {
        try await client
            .from("profiles")
            .upsert(Profile(id: userID, householdId: householdID))
            .execute()
    }
}
