import SwiftUI

struct LoginView: View {
    @AppStorage("is_authenticated") private var isAuthenticated: Bool = false
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showingSignUp = false
    @State private var errorText: String? = nil

    var body: some View {
        ZStack {
            LinearGradient(colors: Theme.bgGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Branding header using existing theme styles
                GlassCard {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                                .frame(width: 64, height: 64)
                            Image(systemName: "heart.text.square.fill").font(.title2)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("HealSpace").font(.title3).bold()
                            Text("Welcome back")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sign in").font(.headline)
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textFieldStyle(.roundedBorder)
                        SecureField("Password", text: $password)
                            .textContentType(.password)
                            .textFieldStyle(.roundedBorder)

                        if let errorText { Text(errorText).font(.caption).foregroundStyle(.red) }

                        Button {
                            signIn()
                        } label: {
                            Text("Sign In").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                Button("Don't have an account? Sign up") { showingSignUp = true }
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)
            }
            .padding()
        }
        .sheet(isPresented: $showingSignUp) {
            SignUpView()
        }
    }

    private func signIn() {
        // Placeholder auth: basic validation only
        guard !email.isEmpty, !password.isEmpty else {
            errorText = "Please fill email and password"
            return
        }
        withAnimation(.spring()) { isAuthenticated = true }
    }
}

#Preview { LoginView() }
