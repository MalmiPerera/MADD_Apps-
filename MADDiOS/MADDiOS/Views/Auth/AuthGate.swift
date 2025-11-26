import SwiftUI

struct AuthGate: View {
    @AppStorage("is_authenticated") private var isAuthenticated: Bool = false
    @AppStorage("has_onboarded") private var hasOnboarded: Bool = false

    var body: some View {
        if isAuthenticated {
            RootTabView()
                .sheet(isPresented: .constant(!hasOnboarded)) {
                    OnboardingView()
                }
        } else {
            LoginView()
        }
    }
}

#Preview { AuthGate() }
