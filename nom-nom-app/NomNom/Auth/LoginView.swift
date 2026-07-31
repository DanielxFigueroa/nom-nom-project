import SwiftUI

/// Email/password sign-in (SPEC.md §4). On success, AuthModel's auth-state
/// listener updates the session and RootView routes forward automatically.
struct LoginView: View {
    @Environment(AuthModel.self) private var auth
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            Text("Welcome Back")
                .font(.largeTitle.bold())
                .padding(.bottom, 12)

            TextField("Email", text: $email)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)

            SecureField("Password", text: $password)
                .textContentType(.password)
                .textFieldStyle(.roundedBorder)

            Button(action: login) {
                Group {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Log In").fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.nnTint)
            .controlSize(.large)
            .disabled(isLoading)
            .padding(.top, 8)

            HStack(spacing: 4) {
                Text("Don't have an account?")
                NavigationLink("Sign Up") { SignupView() }
                    .fontWeight(.semibold)
            }
            .font(.footnote)
            .padding(.top, 8)
        }
        .padding(24)
        .alert("Login Failed", isPresented: errorAlertBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }

    private func login() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both email and password."
            return
        }
        isLoading = true
        Task {
            do {
                try await auth.signIn(email: email, password: password)
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}
