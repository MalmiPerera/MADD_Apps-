import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("is_authenticated") private var isAuthenticated: Bool = false

    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var errorText: String? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: Theme.bgGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Create account").font(.headline)
                                TextField("Full name", text: $name)
                                    .textContentType(.name)
                                    .textFieldStyle(.roundedBorder)
                                TextField("Email", text: $email)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .textFieldStyle(.roundedBorder)
                                SecureField("Password", text: $password)
                                    .textContentType(.newPassword)
                                    .textFieldStyle(.roundedBorder)
                                SecureField("Confirm password", text: $confirmPassword)
                                    .textContentType(.newPassword)
                                    .textFieldStyle(.roundedBorder)

                                if let errorText { Text(errorText).font(.caption).foregroundStyle(.red) }

                                Button {
                                    signUp()
                                } label: {
                                    Text("Create Account").frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }

                        Button("Already have an account? Sign in") { dismiss() }
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
            }
            .navigationTitle("Sign Up")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        }
    }

    private func signUp() {
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            errorText = "Please fill all fields"
            return
        }
        guard password == confirmPassword else {
            errorText = "Passwords do not match"
            return
        }
        withAnimation(.spring()) {
            isAuthenticated = true
        }
    }
}

#Preview { SignUpView() }
