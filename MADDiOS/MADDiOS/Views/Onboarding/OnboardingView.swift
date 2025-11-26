import SwiftUI
import HealthKit

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var didRequestHealth = false
    @State private var healthResultText: String? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: Theme.bgGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Welcome to HealSpace").font(.title3).bold()
                                Text("A calm space to heal and grow.")
                                    .font(.subheadline).foregroundStyle(.secondary)
                                Divider()
                                Text("What you can do:")
                                    .font(.headline)
                                Text("• Journal your thoughts with on-device mood insights\n• Run focus sessions and build momentum\n• View trends and a recovery score\n• Optionally use Health data (steps, energy, mindful minutes)")
                                    .font(.subheadline)
                            }
                        }

                        GlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Privacy & Data").font(.headline)
                                Text("Your data stays on this device (Core Data). Mood analysis runs locally using Apple's NaturalLanguage — nothing leaves your phone.")
                                    .font(.subheadline)
                            }
                        }

                        GlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Health Access (optional)").font(.headline)
                                Text("We can read your Steps, Active Energy, and Mindful Minutes to give better insights.")
                                    .font(.subheadline)
                                Button {
                                    Task {
                                        do {
                                            try await HealthKitService.shared.requestAuthorization()
                                            didRequestHealth = true
                                            healthResultText = "Health access request completed. You can change this anytime in the Health app."
                                        } catch {
                                            didRequestHealth = true
                                            healthResultText = "Could not request Health access: \(error.localizedDescription)"
                                        }
                                    }
                                } label: {
                                    Label("Enable Health Access", systemImage: "heart.fill")
                                }
                                .buttonStyle(.borderedProminent)
                                if let t = healthResultText {
                                    Text(t).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }

                        Button {
                            UserDefaults.standard.set(true, forKey: "has_onboarded")
                            dismiss()
                        } label: {
                            Text("Continue to HealSpace").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
            }
            .navigationTitle("Welcome")
        }
    }
}

#Preview { OnboardingView() }
