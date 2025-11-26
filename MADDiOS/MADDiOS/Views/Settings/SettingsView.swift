import SwiftUI

struct SettingsView: View {
    @AppStorage("daily_reminder_enabled") private var dailyReminder = false
    @AppStorage("theme_preference") private var themePref: String = "system" // system | light | dark

    private var colorSchemeOverride: ColorScheme? {
        switch themePref {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Branding
                GlassCard {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Theme.card.opacity(0.3))
                                .frame(width: 64, height: 64)
                            Image(systemName: "app.fill").font(.title2)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("HealSpace").font(.title3).bold()
                            Text("Personal wellbeing companion")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }

                // Preferences
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Preferences").font(.headline)

                        Toggle(isOn: $dailyReminder) {
                            Text("Daily reminder")
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Theme").font(.subheadline).foregroundStyle(.secondary)
                            Picker("Theme", selection: $themePref) {
                                Text("System").tag("system")
                                Text("Light").tag("light")
                                Text("Dark").tag("dark")
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                }

                // About
                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About").font(.headline)
                        Text("HealSpace helps you reflect with journaling, stay present with focus sessions, and learn from your patterns using on-device sentiment analysis and HealthKit metrics.")
                            .font(.body)
                        Divider()
                        // Replace the placeholders below with your real name and student ID for submission
                        Text("Student: YOUR NAME HERE")
                        Text("Student ID: YOUR-ID-HERE")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
        }
        .preferredColorScheme(colorSchemeOverride)
        .navigationTitle("Settings")
    }
}

#Preview { NavigationStack { SettingsView() } }
