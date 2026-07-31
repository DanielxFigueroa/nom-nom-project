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
    var isLoading = true

    var user: User? { session?.user }
    var isAuthenticated: Bool { session != nil }

    private let client = SupabaseManager.shared

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
    }
}
