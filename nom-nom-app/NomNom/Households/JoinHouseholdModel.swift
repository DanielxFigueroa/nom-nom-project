import Foundation
import Observation

@MainActor
@Observable
final class JoinHouseholdModel {
    var inviteCode = ""
    var isLoading = false
    var errorMessage: String?
    var successMessage: String?
    private let repository = HouseholdRepository()

    func join(auth: AuthModel, recipesRefresh: RecipesRefresh? = nil) async {
        let code = inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard code.count == 6 else {
            errorMessage = "Please enter a valid 6-character invite code."
            return
        }
        isLoading = true
        errorMessage = nil
        successMessage = nil
        do {
            guard let householdID = try await repository.findHousehold(inviteCode: code) else {
                errorMessage = "No household found with that invite code."
                isLoading = false
                return
            }
            guard let userID = auth.user?.id else {
                isLoading = false
                return
            }
            try await repository.joinHousehold(userID: userID, householdID: householdID)
            await auth.refreshJoinedHouseholds()
            inviteCode = ""
            successMessage = "Successfully joined household!"
            recipesRefresh?.trigger()
            NotificationCenter.default.post(name: .recipesRefresh, object: nil)
        } catch {
            errorMessage = "Could not join household. Please try again."
        }
        isLoading = false
    }
}
