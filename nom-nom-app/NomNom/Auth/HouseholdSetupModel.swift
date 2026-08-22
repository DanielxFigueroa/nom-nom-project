import Foundation
import Observation

/// Drives the Household Setup screen (SPEC.md §4). On success it refreshes the
/// profile so RootView advances into the main app.
@MainActor
@Observable
final class HouseholdSetupModel {
    var name = ""
    var inviteCode = ""
    var isLoading = false
    var errorMessage: String?
    var pendingHousehold: Household?

    var isPendingApproval: Bool { pendingHousehold != nil }
    var pendingHouseholdDisplayName: String {
        if let name = pendingHousehold?.name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
            return name
        }
        if let id = pendingHousehold?.id {
            return "Household (\(id.uuidString.suffix(4)))"
        }
        return "the household"
    }

    private let repository = HouseholdRepository()

    func createHousehold(auth: AuthModel) async {
        guard let userID = auth.user?.id else { return }
        isLoading = true
        errorMessage = nil
        do {
            let householdID = try await repository.createHousehold(name: name, userID: userID)
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
        let code = inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard code.count == 6 else {
            errorMessage = "Please enter a valid 6-character invite code."
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            guard let household = try await repository.fetchHousehold(inviteCode: code) else {
                errorMessage = "Could not find a household with that invite code."
                isLoading = false
                return
            }

            let existingMembership = try await repository.fetchMembership(userID: userID, householdID: household.id)

            if let existing = existingMembership {
                if existing.status == .active {
                    try await repository.linkProfile(userID: userID, householdID: household.id)
                    await auth.refreshProfile()
                    return
                }
            }

            if household.requireApproval {
                try await repository.joinHousehold(
                    userID: userID,
                    householdID: household.id,
                    status: HouseholdMember.MemberStatus.pending.rawValue,
                    role: HouseholdMember.MemberRole.member.rawValue
                )
                await auth.refreshJoinedHouseholds()
                pendingHousehold = household
                isLoading = false
            } else {
                try await repository.linkProfile(userID: userID, householdID: household.id)
                await auth.refreshProfile()
            }
        } catch {
            errorMessage = "Could not find a household with that invite code."
            isLoading = false
        }
    }

    func checkPendingStatus(auth: AuthModel) async {
        guard let userID = auth.user?.id, let household = pendingHousehold else { return }
        isLoading = true
        errorMessage = nil
        do {
            if let membership = try await repository.fetchMembership(userID: userID, householdID: household.id) {
                if membership.status == .active {
                    try await repository.linkProfile(userID: userID, householdID: household.id)
                    await auth.refreshProfile()
                    return
                } else if membership.status == .declined {
                    errorMessage = "Your join request was declined. You can create a new household or try another code."
                    pendingHousehold = nil
                    isLoading = false
                    return
                }
            }
            errorMessage = "Still waiting for approval from the household owner."
        } catch {
            errorMessage = "Failed to check approval status. Please try again."
        }
        isLoading = false
    }

    func cancelPending() {
        pendingHousehold = nil
        inviteCode = ""
        errorMessage = nil
    }
}
