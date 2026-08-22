import SwiftUI

/// Owner-facing member management screen and household details view.
/// Shows pending join requests (with batch & single approval/decline), active members (with removal),
/// and household settings (require approval toggle).
struct HouseholdDetailView: View {
    @Environment(AuthModel.self) private var auth
    @State private var model: HouseholdDetailModel
    @State private var copied = false

    init(household: Household) {
        _model = State(initialValue: HouseholdDetailModel(household: household))
    }

    private var isOwner: Bool {
        model.isOwner(auth: auth)
    }

    private var householdDisplayName: String {
        let name = model.household.name?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let name, !name.isEmpty {
            return name
        }
        return "Household (\(model.household.id.uuidString.suffix(4)))"
    }

    var body: some View {
        List {
            // Error banner if any
            if let errorMessage = model.errorMessage {
                Section {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                }
            }

            // Household Info Section (Basic Info for all members)
            Section("Household Info") {
                if let name = model.household.name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
                    LabeledContent("Name", value: name)
                }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Invite Code")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(model.household.inviteCode)
                            .font(.title3.weight(.bold).monospaced())
                            .foregroundStyle(Color.nnTint)
                            .tracking(2)
                    }
                    Spacer()
                    Button {
                        UIPasteboard.general.string = model.household.inviteCode
                        copied = true
                        Task {
                            try? await Task.sleep(nanoseconds: 2_000_000_000)
                            copied = false
                        }
                    } label: {
                        Label(copied ? "Copied!" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                            .font(.subheadline)
                            .foregroundStyle(Color.nnTint)
                    }
                    .animation(.easeInOut, value: copied)
                }

                LabeledContent("Your Role", value: isOwner ? "Owner" : "Member")
            }

            // Pending Requests Section (Owner only, only when pending requests exist)
            if isOwner && !model.pendingRequests.isEmpty {
                Section {
                    ForEach(model.pendingRequests) { member in
                        PendingRequestRow(
                            member: member,
                            isSelected: model.selectedPendingIDs.contains(member.userId),
                            currentUserID: auth.user?.id,
                            currentUserEmail: auth.user?.email,
                            onToggleSelect: {
                                model.toggleSelection(for: member.userId)
                            },
                            onAccept: {
                                Task {
                                    await model.acceptRequest(member, auth: auth)
                                }
                            },
                            onDecline: {
                                Task {
                                    await model.declineRequest(member, auth: auth)
                                }
                            }
                        )
                    }

                    Button {
                        Task {
                            await model.acceptSelected(auth: auth)
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Text(model.selectedPendingIDs.isEmpty ? "Accept All Selected" : "Accept All Selected (\(model.selectedPendingIDs.count))")
                                .bold()
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .disabled(model.selectedPendingIDs.isEmpty)
                } header: {
                    HStack(spacing: 8) {
                        Text("Pending Requests")

                        Text("\(model.pendingRequests.count)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.15))
                            .foregroundColor(.orange)
                            .clipShape(Capsule())
                    }
                }
            }

            // Active Members Section (Owner only)
            if isOwner {
                Section("Active Members (\(model.activeMembers.count))") {
                    if model.activeMembers.isEmpty && !model.isLoading {
                        Text("No members found.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(model.activeMembers) { member in
                            MemberRow(
                                member: member,
                                isCurrentHouseholdOwner: isOwner,
                                currentUserID: auth.user?.id,
                                currentUserEmail: auth.user?.email,
                                onRemove: {
                                    model.memberToRemove = member
                                    model.showRemoveAlert = true
                                }
                            )
                        }
                    }
                }
            }

            // Household Settings Section (Owner only)
            if isOwner {
                Section {
                    Toggle("Require approval for new members", isOn: Binding(
                        get: { model.requireApproval },
                        set: { newValue in
                            Task {
                                await model.updateApprovalSetting(newValue, auth: auth)
                            }
                        }
                    ))

                    Text("When enabled, new members must be approved by you before they can see recipes.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("Household Settings")
                }
            }
        }
        .navigationTitle(householdDisplayName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await model.load(auth: auth)
        }
        .refreshable {
            await model.load(auth: auth)
        }
        .alert("Remove Member", isPresented: $model.showRemoveAlert, presenting: model.memberToRemove) { member in
            Button("Cancel", role: .cancel) {
                model.memberToRemove = nil
            }
            Button("Remove", role: .destructive) {
                Task {
                    await model.removeMember(member, auth: auth)
                    model.memberToRemove = nil
                }
            }
        } message: { member in
            let memberName = member.displayName(currentUserID: auth.user?.id, currentUserEmail: auth.user?.email)
            Text("Remove \(memberName)? They will lose access to all recipes in \(householdDisplayName).")
        }
    }
}
