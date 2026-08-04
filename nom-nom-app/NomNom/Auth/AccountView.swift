import SwiftUI

/// Account sheet: shows who you're signed in as (email, user id, household id)
/// and a sign-out action. Uses `AuthModel.signOut()` (SPEC.md §5).
struct AccountView: View {
    @Environment(AuthModel.self) private var auth
    @Environment(\.dismiss) private var dismiss
    @State private var showFolders = false

    var body: some View {
        NavigationStack {
            List {
                Section("Signed in as") {
                    LabeledContent("Email", value: auth.user?.email ?? "—")
                    LabeledContent("User ID", value: auth.user?.id.uuidString ?? "—")
                        .textSelection(.enabled)
                }
                Section("Household") {
                    LabeledContent("Household ID", value: auth.householdId?.uuidString ?? "—")
                        .textSelection(.enabled)
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
            .sheet(isPresented: $showFolders) {
                if let householdID = auth.householdId {
                    FolderManagerView(householdID: householdID)
                }
            }
        }
    }
}
