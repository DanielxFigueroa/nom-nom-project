import Foundation
import Observation

/// Drives the Household Setup screen (SPEC.md §4). On success it refreshes the
/// profile so RootView advances into the main app.
@MainActor
@Observable
final class HouseholdSetupModel {
    var inviteCode = ""
    var isLoading = false
    var errorMessage: String?

    private let repository = HouseholdRepository()

    func createHousehold(auth: AuthModel) async {
        guard let userID = auth.user?.id else { return }
        isLoading = true
        errorMessage = nil
        do {
            let householdID = try await repository.createHousehold()
            try await repository.linkProfile(userID: userID, householdID: householdID)
            await auth.refreshProfile()
            // On success RootView swaps this view out; no need to reset isLoading.
        } catch {
            errorMessage = "Failed to create household. Please try again."
            isLoading = false
        }
    }

    func joinHousehold(auth: AuthModel) async {
        guard let userID = auth.user?.id else { return }
        guard inviteCode.count == 6 else {
            errorMessage = "Please enter a valid 6-character invite code."
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            guard let householdID = try await repository.findHousehold(inviteCode: inviteCode) else {
                errorMessage = "Could not find a household with that invite code."
                isLoading = false
                return
            }
            try await repository.linkProfile(userID: userID, householdID: householdID)
            await auth.refreshProfile()
        } catch {
            errorMessage = "Could not find a household with that invite code."
            isLoading = false
        }
    }
}
