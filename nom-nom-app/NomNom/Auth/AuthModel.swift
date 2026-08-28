import Foundation
import Observation
import Supabase

/// App-wide auth + household state. Mirrors the RN `AuthContext`
/// (`legacy-react-native/recipe-app/src/contexts/AuthContext.tsx`):
/// restores the persisted session on launch, listens for auth changes, and
/// resolves the user's `household_id` from the `profiles` table.
@MainActor
@Observable
final class AuthModel {
    var session: Session?
    var householdId: UUID?
    var joinedHouseholds: [Household] = []
    var pendingHouseholds: [Household] = []
    var userMemberships: [HouseholdMember] = []
    var pendingRequestCounts: [UUID: Int] = [:]
    var isLoading = true

    var user: User? { session?.user }
    var isAuthenticated: Bool { session != nil }

    var joinedHouseholdIds: [UUID] { joinedHouseholds.map(\.id) }
    var totalPendingCount: Int {
        pendingRequestCounts.values.reduce(0, +)
    }

    private let client = SupabaseManager.shared
    private let householdRepository = HouseholdRepository()

    func isOwner(of householdID: UUID) -> Bool {
        if let membership = userMemberships.first(where: { $0.householdId == householdID }) {
            return membership.role == .owner
        }
        return householdId == householdID
    }

    /// Call once at app launch. Restores any persisted session, resolves the
    /// household, then keeps observing auth-state changes.
    func start() async {
        session = try? await client.auth.session
        await refreshProfile()
        isLoading = false

        for await (event, session) in client.auth.authStateChanges {
            self.session = session
            switch event {
            case .signedIn, .initialSession, .tokenRefreshed, .userUpdated:
                await refreshProfile()
            case .signedOut:
                householdId = nil
                joinedHouseholds = []
                pendingHouseholds = []
                userMemberships = []
                pendingRequestCounts = [:]
            default:
                break
            }
        }
    }

    /// Re-reads `profiles.household_id` for the current user. Call after the
    /// household-setup flow so routing advances into the main app.
    func refreshProfile() async {
        guard let userID = user?.id else {
            householdId = nil
            joinedHouseholds = []
            pendingHouseholds = []
            userMemberships = []
            pendingRequestCounts = [:]
            return
        }
        do {
            let profile: Profile? = try await client
                .from("profiles")
                .select("id, household_id")
                .eq("id", value: userID)
                .maybeSingle()
                .execute()
                .value
            householdId = profile?.householdId
        } catch {
            householdId = nil
        }
        await refreshJoinedHouseholds()
    }

    func refreshJoinedHouseholds() async {
        guard let userID = user?.id else {
            joinedHouseholds = []
            pendingHouseholds = []
            userMemberships = []
            pendingRequestCounts = [:]
            return
        }
        do {
            var fetchedHouseholds = try await householdRepository.fetchJoinedHouseholds(userID: userID)
            let fetchedPendingHouseholds = (try? await householdRepository.fetchPendingHouseholds(userID: userID)) ?? []
            var memberships = (try? await householdRepository.fetchUserMemberships(userID: userID)) ?? []

            // Auto-heal: If profile household is set but not present in joinedHouseholds, add it & ensure membership
            if let primaryID = householdId, !fetchedHouseholds.contains(where: { $0.id == primaryID }) {
                if let primaryHousehold = try? await householdRepository.fetchHousehold(id: primaryID) {
                    fetchedHouseholds.insert(primaryHousehold, at: 0)
                    try? await householdRepository.joinHousehold(
                        userID: userID,
                        householdID: primaryID,
                        status: HouseholdMember.MemberStatus.active.rawValue,
                        role: HouseholdMember.MemberRole.owner.rawValue
                    )
                    memberships = (try? await householdRepository.fetchUserMemberships(userID: userID)) ?? memberships
                }
            }

            joinedHouseholds = fetchedHouseholds
            pendingHouseholds = fetchedPendingHouseholds
            userMemberships = memberships

            var counts: [UUID: Int] = [:]
            for household in joinedHouseholds {
                if isOwner(of: household.id) {
                    if let pending = try? await householdRepository.fetchPendingRequests(householdID: household.id) {
                        counts[household.id] = pending.count
                    }
                }
            }
            pendingRequestCounts = counts
        } catch {
            // Resilient fallback: at least load primary household if available
            if let primaryID = householdId, let primaryHousehold = try? await householdRepository.fetchHousehold(id: primaryID) {
                joinedHouseholds = [primaryHousehold]
                userMemberships = [
                    HouseholdMember(
                        userId: userID,
                        householdId: primaryID,
                        status: .active,
                        role: .owner
                    )
                ]
            } else {
                joinedHouseholds = []
                userMemberships = []
            }
            pendingHouseholds = []
            pendingRequestCounts = [:]
        }
    }

    func signIn(email: String, password: String) async throws {
        try await client.auth.signIn(email: email, password: password)
    }

    /// Returns `true` if a session was created immediately (email confirmation
    /// disabled), `false` if the user must confirm their email first.
    @discardableResult
    func signUp(email: String, password: String) async throws -> Bool {
        let response = try await client.auth.signUp(email: email, password: password)
        return response.session != nil
    }

    /// Not present in the RN app — added per SPEC.md §5.
    func signOut() async {
        try? await client.auth.signOut()
        session = nil
        householdId = nil
        joinedHouseholds = []
        pendingHouseholds = []
        userMemberships = []
        pendingRequestCounts = [:]
    }
}
