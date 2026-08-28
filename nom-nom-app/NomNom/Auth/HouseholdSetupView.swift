import SwiftUI

/// Create (generate 6-char code) or join a household by invite code (SPEC.md §4).
/// Ports RN `app/(auth)/household-setup.tsx`.
struct HouseholdSetupView: View {
    @Environment(AuthModel.self) private var auth
    @State private var model = HouseholdSetupModel()

    var body: some View {
        @Bindable var model = model

        ScrollView {
            VStack(spacing: 24) {
                if model.isPendingApproval {
                    pendingApprovalView
                } else {
                    setupFormsView
                }
            }
            .padding(24)
        }
    }

    private var pendingApprovalView: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 56))
                .foregroundColor(.orange)
                .padding(.top, 32)

            Text("Join Request Sent")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            Text("Pending Approval")
                .font(.caption)
                .fontWeight(.bold)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.15))
                .foregroundColor(.orange)
                .clipShape(Capsule())

            VStack(spacing: 12) {
                Text("Your request to join **\(model.pendingHouseholdDisplayName)** is waiting for the household owner to accept you.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)

                Text("You can wait for approval, check your status, or create your own household to start using NomNom right away.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)

            if let errorMessage = model.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(Color.nnError)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }

            VStack(spacing: 12) {
                Button {
                    Task { await model.checkPendingStatus(auth: auth) }
                } label: {
                    buttonLabel("Check Approval Status")
                }
                .buttonStyle(.borderedProminent)
                .tint(.nnTint)
                .controlSize(.large)
                .disabled(model.isLoading)

                Button {
                    model.cancelPending()
                } label: {
                    Text("Create a Household Instead")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.nnTint)
                .controlSize(.large)
                .disabled(model.isLoading)

                Button {
                    model.cancelPending()
                } label: {
                    Text("Try Another Code")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
                .disabled(model.isLoading)
            }
            .padding(.top, 12)
        }
    }

    private var setupFormsView: some View {
        VStack(spacing: 24) {
            Text("Set Up Your Household")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .padding(.top, 40)

            if let errorMessage = model.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(Color.nnError)
                    .multilineTextAlignment(.center)
            }

            // Create
            VStack(alignment: .leading, spacing: 10) {
                Text("Create a New Household")
                    .font(.title3.weight(.semibold))
                Text("Start fresh and invite others to join your meal plan.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextField("Household name (optional)", text: $model.name)
                    .textFieldStyle(.roundedBorder)
                Button {
                    Task { await model.createHousehold(auth: auth) }
                } label: {
                    buttonLabel("Create Household")
                }
                .buttonStyle(.borderedProminent)
                .tint(.nnTint)
                .controlSize(.large)
                .disabled(model.isLoading)
            }

            dividerOr

            // Join
            VStack(alignment: .leading, spacing: 10) {
                Text("Join an Existing Household")
                    .font(.title3.weight(.semibold))
                TextField("Enter 6-digit invite code", text: $model.inviteCode)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: model.inviteCode) { _, newValue in
                        let upper = newValue.uppercased()
                        model.inviteCode = String(upper.prefix(6))
                    }
                Button {
                    Task { await model.joinHousehold(auth: auth) }
                } label: {
                    buttonLabel("Join Household")
                }
                .buttonStyle(.borderedProminent)
                .tint(.nnSuccess)
                .controlSize(.large)
                .disabled(model.isLoading)
            }
        }
    }

    private func buttonLabel(_ title: String) -> some View {
        Group {
            if model.isLoading {
                ProgressView().tint(.white)
            } else {
                Text(title).fontWeight(.semibold)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var dividerOr: some View {
        HStack {
            VStack { Divider() }
            Text("OR").font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
            VStack { Divider() }
        }
    }
}
