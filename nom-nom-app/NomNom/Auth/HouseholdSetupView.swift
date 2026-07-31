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
            .padding(24)
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
