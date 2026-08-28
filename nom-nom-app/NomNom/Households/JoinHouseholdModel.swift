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
            guard let household = try await repository.fetchHousehold(inviteCode: code) else {
                errorMessage = "No household found with that invite code."
                isLoading = false
                return
            }
            guard let userID = auth.user?.id else {
                isLoading = false
                return
            }

            let existingMembership = try await repository.fetchMembership(userID: userID, householdID: household.id)

            if let existing = existingMembership {
                if existing.status == .pending {
                    errorMessage = "You already have a pending request for this household."
                    isLoading = false
                    return
                } else if existing.status == .active {
                    errorMessage = "You are already a member of this household."
                    isLoading = false
                    return
                }
                // If existing.status == .declined, allow re-requesting below
            }

            if household.requireApproval {
                try await repository.joinHousehold(
                    userID: userID,
                    householdID: household.id,
                    status: HouseholdMember.MemberStatus.pending.rawValue,
                    role: HouseholdMember.MemberRole.member.rawValue
                )
                await auth.refreshJoinedHouseholds()
                inviteCode = ""
                successMessage = "Request sent! Waiting for the household owner to accept you."
            } else {
                try await repository.joinHousehold(
                    userID: userID,
                    householdID: household.id,
                    status: HouseholdMember.MemberStatus.active.rawValue,
                    role: HouseholdMember.MemberRole.member.rawValue
                )
                await auth.refreshJoinedHouseholds()
                inviteCode = ""
                successMessage = "Successfully joined household!"
                recipesRefresh?.trigger()
                NotificationCenter.default.post(name: .recipesRefresh, object: nil)
            }

            Task { [weak self] in
                try? await Task.sleep(nanoseconds: 3_500_000_000)
                self?.successMessage = nil
            }
        } catch {
            errorMessage = "Could not join household. Please try again."
        }
        isLoading = false
    }
}
