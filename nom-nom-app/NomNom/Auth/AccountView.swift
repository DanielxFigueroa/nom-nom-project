import SwiftUI

/// Account sheet: shows who you're signed in as (email, user id, household id)
/// and a sign-out action. Uses `AuthModel.signOut()` (SPEC.md §5).
struct AccountView: View {
    @Environment(AuthModel.self) private var auth
    @Environment(\.dismiss) private var dismiss
    @State private var showFolders = false
    @State private var ownedHousehold: Household?
    @State private var copied = false
    @Bindable private var pcosStore = PCOSSettingsStore.shared

    var body: some View {
        NavigationStack {
            List {
                Section("Signed in as") {
                    LabeledContent("Email", value: auth.user?.email ?? "—")
                    LabeledContent("User ID", value: auth.user?.id.uuidString ?? "—")
                        .textSelection(.enabled)
                }
                if let householdID = auth.householdId {
                    Section("My Household") {
                        if let household = ownedHousehold {
                            LabeledContent("Name", value: household.name ?? "My Household")

                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Invite Code")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Text(household.inviteCode)
                                        .font(.title2.weight(.bold).monospaced())
                                        .foregroundStyle(Color.nnTint)
                                        .tracking(4)
                                }
                                Spacer()
                                Button {
                                    UIPasteboard.general.string = household.inviteCode
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
                            .textSelection(.enabled)
                        } else {
                            ProgressView()
                        }

                        LabeledContent("Household ID", value: householdID.uuidString)
                            .textSelection(.enabled)
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                } else {
                    Section("My Household") {
                        Text("You haven't created a household. Create one in the Households tab.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Health & Dietary Lenses") {
                    PCOSSettingsView(store: pcosStore)
                }

                if let householdID = auth.householdId {
                    Section("Folders") {
                        Button {
                            showFolders = true
                        } label: {
                            Label("Manage Folders", systemImage: "folder")
                                .foregroundStyle(Color.primary)
                        }
                    }
                }
                Section {
                    Button(role: .destructive) {
                        Task {
                            await auth.signOut()
                            dismiss()
                        }
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                if let id = auth.householdId {
                    ownedHousehold = try? await HouseholdRepository().fetchHousehold(id: id)
                }
                if let userID = auth.user?.id {
                    await pcosStore.loadSettings(userID: userID)
                }
            }
            .sheet(isPresented: $showFolders) {
                if let householdID = auth.householdId {
                    FolderManagerView(householdID: householdID)
                }
            }
        }
    }
}
