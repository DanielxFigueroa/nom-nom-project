import SwiftUI

/// Create account (SPEC.md §4). If Supabase returns a session (email confirmation
/// disabled), RootView advances to Household Setup automatically; otherwise the
/// user is told to confirm their email.
struct SignupView: View {
    @Environment(AuthModel.self) private var auth
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showConfirmEmail = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Create Account")
                .font(.largeTitle.bold())
                .padding(.bottom, 12)

            TextField("Email", text: $email)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)

            SecureField("Password", text: $password)
                .textContentType(.newPassword)
                .textFieldStyle(.roundedBorder)

            Button(action: signUp) {
                Group {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Sign Up").fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.nnSuccess)
            .controlSize(.large)
            .disabled(isLoading)
            .padding(.top, 8)
        }
        .padding(24)
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Sign Up Failed", isPresented: errorAlertBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
        .alert("Check your email", isPresented: $showConfirmEmail) {
            Button("OK") { dismiss() }
        } message: {
            Text("Account created. Please confirm your email, then log in.")
        }
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }

    private func signUp() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both email and password."
            return
        }
        isLoading = true
        Task {
            do {
                let signedIn = try await auth.signUp(email: email, password: password)
                if !signedIn {
                    // Email confirmation required — no active session yet.
                    isLoading = false
                    showConfirmEmail = true
                }
                // If signedIn, RootView swaps to Household Setup automatically.
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}
