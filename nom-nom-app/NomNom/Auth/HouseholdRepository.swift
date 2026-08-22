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
        let status: String
        let role: String
    }

    // MARK: - Multi-Household Methods

    /// Query `household_members` joined to `households` to get all households for the user.
    func fetchJoinedHouseholds(userID: UUID) async throws -> [Household] {
        let rows: [HouseholdMemberJoin] = try await client
            .from("household_members")
            .select("household_id, households(*)")
            .eq("user_id", value: userID)
            .eq("status", value: HouseholdMember.MemberStatus.active.rawValue)
            .execute()
            .value
        return rows.compactMap { $0.households }
    }

    /// INSERT INTO `household_members(user_id, household_id)` ON CONFLICT DO NOTHING.
    /// Approval-aware: checks `require_approval` on the target household if `status` is nil.
    func joinHousehold(userID: UUID, householdID: UUID, status: String? = nil, role: String? = nil) async throws {
        let targetStatus: String
        if let status = status {
            targetStatus = status
        } else {
            let household = try? await fetchHousehold(id: householdID)
            let requireApproval = household?.requireApproval ?? false
            targetStatus = requireApproval ? HouseholdMember.MemberStatus.pending.rawValue : HouseholdMember.MemberStatus.active.rawValue
        }
        let targetRole = role ?? HouseholdMember.MemberRole.member.rawValue

        let member = HouseholdMemberInsert(user_id: userID, household_id: householdID, status: targetStatus, role: targetRole)
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
    /// Also inserts into `household_members` as an active owner if `userID` is provided.
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
            try await joinHousehold(userID: userID, householdID: household.id, status: HouseholdMember.MemberStatus.active.rawValue, role: HouseholdMember.MemberRole.owner.rawValue)
        }
        return household.id
    }

    /// Looks up a household id by invite code (case-insensitive). nil if not found.
    /// Also calls `joinHousehold` if `userID` is provided and a household is found.
    func findHousehold(inviteCode: String, userID: UUID? = nil) async throws -> UUID? {
        let household: Household? = try await client
            .from("households")
            .select("id, invite_code, name, require_approval")
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

    // MARK: - Member & Approval Management

    /// Fetch pending membership requests for a household (owner only).
    func fetchPendingRequests(householdID: UUID) async throws -> [HouseholdMember] {
        try await client
            .from("household_members")
            .select("*")
            .eq("household_id", value: householdID)
            .eq("status", value: HouseholdMember.MemberStatus.pending.rawValue)
            .execute()
            .value
    }

    /// Fetch active members of a household.
    func fetchActiveMembers(householdID: UUID) async throws -> [HouseholdMember] {
        try await client
            .from("household_members")
            .select("*")
            .eq("household_id", value: householdID)
            .eq("status", value: HouseholdMember.MemberStatus.active.rawValue)
            .execute()
            .value
    }

    /// Accept a pending member request.
    func acceptMember(userID: UUID, householdID: UUID) async throws {
        try await client
            .from("household_members")
            .update(["status": HouseholdMember.MemberStatus.active.rawValue])
            .eq("user_id", value: userID)
            .eq("household_id", value: householdID)
            .execute()
    }

    /// Accept multiple pending member requests in batch.
    func acceptMembers(userIDs: [UUID], householdID: UUID) async throws {
        guard !userIDs.isEmpty else { return }
        try await client
            .from("household_members")
            .update(["status": HouseholdMember.MemberStatus.active.rawValue])
            .in("user_id", values: userIDs)
            .eq("household_id", value: householdID)
            .execute()
    }

    /// Decline a pending member request.
    func declineMember(userID: UUID, householdID: UUID) async throws {
        try await client
            .from("household_members")
            .update(["status": HouseholdMember.MemberStatus.declined.rawValue])
            .eq("user_id", value: userID)
            .eq("household_id", value: householdID)
            .execute()
    }

    /// Remove an active member from a household (owner only).
    func removeMember(userID: UUID, householdID: UUID) async throws {
        try await client
            .from("household_members")
            .delete()
            .eq("user_id", value: userID)
            .eq("household_id", value: householdID)
            .execute()
    }

    /// Self-service: leave a household.
    func leaveHousehold(userID: UUID, householdID: UUID) async throws {
        try await client
            .from("household_members")
            .delete()
            .eq("user_id", value: userID)
            .eq("household_id", value: householdID)
            .execute()
    }

    /// Update household approval requirement setting.
    func updateApprovalSetting(householdID: UUID, requireApproval: Bool) async throws {
        try await client
            .from("households")
            .update(["require_approval": requireApproval])
            .eq("id", value: householdID)
            .execute()
    }

    /// Fetch the owner member row of a household.
    func fetchHouseholdOwner(householdID: UUID) async throws -> HouseholdMember? {
        try await client
            .from("household_members")
            .select("*")
            .eq("household_id", value: householdID)
            .eq("role", value: HouseholdMember.MemberRole.owner.rawValue)
            .maybeSingle()
            .execute()
            .value
    }

    /// Fetch all membership rows for a user across all households.
    func fetchUserMemberships(userID: UUID) async throws -> [HouseholdMember] {
        try await client
            .from("household_members")
            .select("*")
            .eq("user_id", value: userID)
            .execute()
            .value
    }
}
