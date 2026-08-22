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
    var showRemoveAlert = false

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

            activeMembers = try await repository.fetchActiveMembers(householdID: household.id)

            if isOwner(auth: auth) {
                pendingRequests = try await repository.fetchPendingRequests(householdID: household.id)
                let validIDs = Set(pendingRequests.map(\.userId))
                selectedPendingIDs = selectedPendingIDs.intersection(validIDs)
            } else {
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

    func updateApprovalSetting(_ newValue: Bool) async {
        let oldValue = requireApproval
        requireApproval = newValue

        do {
            try await repository.updateApprovalSetting(householdID: household.id, requireApproval: newValue)
        } catch {
            requireApproval = oldValue
            errorMessage = error.localizedDescription
        }
    }
}
