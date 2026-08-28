import Foundation
import Observation

/// View model for `HouseholdDetailView`.
/// Handles member listing, pending request approval/declining/batching, member removal, and approval settings.
@Observable
@MainActor
final class HouseholdDetailModel {
    var household: Household
    var activeMembers: [HouseholdMember] = []
    var pendingRequests: [HouseholdMember] = []
    var selectedPendingIDs: Set<UUID> = []
    var requireApproval: Bool
    var isLoading = false
    var errorMessage: String?
    var memberToRemove: HouseholdMember?
    var memberToTransfer: HouseholdMember?
    var showRemoveAlert = false
    var showTransferAlert = false
    var showLeaveAlert = false

    private let repository = HouseholdRepository()

    init(household: Household) {
        self.household = household
        self.requireApproval = household.requireApproval
    }

    func isOwner(auth: AuthModel) -> Bool {
        auth.isOwner(of: household.id)
    }

    func load(auth: AuthModel) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            if let updated = try await repository.fetchHousehold(id: household.id) {
                household = updated
                requireApproval = updated.requireApproval
            }

            if isOwner(auth: auth) {
                activeMembers = try await repository.fetchActiveMembers(householdID: household.id)
                pendingRequests = try await repository.fetchPendingRequests(householdID: household.id)
                let validIDs = Set(pendingRequests.map(\.userId))
                selectedPendingIDs = selectedPendingIDs.intersection(validIDs)
            } else {
                activeMembers = []
                pendingRequests = []
                selectedPendingIDs = []
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleSelection(for userID: UUID) {
        if selectedPendingIDs.contains(userID) {
            selectedPendingIDs.remove(userID)
        } else {
            selectedPendingIDs.insert(userID)
        }
    }

    func acceptRequest(_ member: HouseholdMember, auth: AuthModel) async {
        do {
            try await repository.acceptMember(userID: member.userId, householdID: household.id)
            selectedPendingIDs.remove(member.userId)
            await load(auth: auth)
            await auth.refreshJoinedHouseholds()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func declineRequest(_ member: HouseholdMember, auth: AuthModel) async {
        do {
            try await repository.declineMember(userID: member.userId, householdID: household.id)
            selectedPendingIDs.remove(member.userId)
            await load(auth: auth)
            await auth.refreshJoinedHouseholds()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func acceptSelected(auth: AuthModel) async {
        let userIDs = Array(selectedPendingIDs)
        guard !userIDs.isEmpty else { return }

        do {
            try await repository.acceptMembers(userIDs: userIDs, householdID: household.id)
            selectedPendingIDs.removeAll()
            await load(auth: auth)
            await auth.refreshJoinedHouseholds()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeMember(_ member: HouseholdMember, auth: AuthModel) async {
        do {
            try await repository.removeMember(userID: member.userId, householdID: household.id)
            await load(auth: auth)
            await auth.refreshJoinedHouseholds()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func transferOwnership(to newOwner: HouseholdMember, auth: AuthModel, recipesRefresh: RecipesRefresh? = nil) async -> Bool {
        guard let currentUserID = auth.user?.id else { return false }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await repository.transferOwnership(
                householdID: household.id,
                newOwnerID: newOwner.userId,
                currentOwnerID: currentUserID
            )
            await auth.refreshProfile()
            await load(auth: auth)
            recipesRefresh?.trigger()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func updateApprovalSetting(_ newValue: Bool, auth: AuthModel? = nil) async {
        let oldValue = requireApproval
        requireApproval = newValue

        do {
            try await repository.updateApprovalSetting(householdID: household.id, requireApproval: newValue)
            household.requireApproval = newValue
            await auth?.refreshJoinedHouseholds()
        } catch {
            requireApproval = oldValue
            errorMessage = error.localizedDescription
        }
    }

    func leaveHousehold(auth: AuthModel, recipesRefresh: RecipesRefresh? = nil) async -> Bool {
        guard let userID = auth.user?.id else { return false }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await repository.leaveHousehold(userID: userID, householdID: household.id)
            await auth.refreshJoinedHouseholds()
            if auth.householdId == household.id {
                let nextID = auth.joinedHouseholds.first?.id
                auth.householdId = nextID
                if let nextID {
                    try? await repository.linkProfile(userID: userID, householdID: nextID)
                } else {
                    struct ProfileHouseholdUpdate: Encodable {
                        let household_id: UUID?
                    }
                    try? await SupabaseManager.shared.from("profiles").update(ProfileHouseholdUpdate(household_id: nil)).eq("id", value: userID).execute()
                }
            }
            recipesRefresh?.trigger()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
