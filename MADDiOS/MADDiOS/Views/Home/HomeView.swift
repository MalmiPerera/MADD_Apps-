
import SwiftUI
import CoreData
import SwiftUI

struct HomeView: View {
    @Environment(\.managedObjectContext) private var context
    @StateObject private var insights = InsightsViewModel()
    @Binding var selectedTab: RootTabView.AppTab

    @State private var animatedScore: Double = 0

    var body: some View {
        ZStack {
            LinearGradient(colors: Theme.bgGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Theme.spacingL) {
                    // Greeting header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(greeting)
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text(motivationalQuote)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: greetingIcon)
                            .font(.largeTitle)
                            .foregroundStyle(Theme.accent)
                    }
                    .padding()
                    .slideIn(delay: 0.1)

                    // Recovery snapshot
                    GlassCard {
                        VStack(spacing: 12) {
                            HStack(alignment: .center) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Recovery Snapshot").font(.headline)
                                    Text(progressMessage(for: Int(animatedScore)))
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                RecoveryGauge(value: animatedScore, title: "Recovery", subtitle: "Overall score")
                            }
                            ProgressView(value: min(max(animatedScore/100, 0), 1))
                                .tint(Theme.accent)
                        }
                    }
                    .slideIn(delay: 0.15)

                    // Quick actions
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.spacingM) {
                        QuickActionCard(icon: "plus.circle.fill", title: "New Journal", color: .purple) { selectedTab = .journal }
                            .slideIn(delay: 0.25)
                        QuickActionCard(icon: "timer", title: "Focus", color: .blue) { selectedTab = .focus }
                            .slideIn(delay: 0.3)
                        QuickActionCard(icon: "heart.fill", title: "Health", color: .red) { selectedTab = .health }
                            .slideIn(delay: 0.35)
                        QuickActionCard(icon: "chart.bar.fill", title: "Insights", color: .green) { selectedTab = .insights }
                            .slideIn(delay: 0.4)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Home")
        .onAppear {
            insights.fetch(context: context)
            withAnimation(.easeInOut(duration: 0.6)) {
                animatedScore = Double(insights.recoveryScore)
            }
        }
        .onChange(of: insights.recoveryScore) { _, newValue in
            withAnimation(.easeInOut(duration: 0.6)) {
                animatedScore = Double(newValue)
            }
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
        }
    }

    private var greetingIcon: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "sunrise.fill"
        case 12..<17: return "sun.max.fill"
        default: return "moon.stars.fill"
        }
    }

    private var motivationalQuote: String {
        "Small steps, gentle heart."
    }

    private func progressMessage(for score: Int) -> String {
        switch score {
        case 0..<30: return "It’s okay to take it slow. You’re showing up."
        case 30..<60: return "You’re making steady progress. Keep going."
        case 60..<85: return "Great momentum. Your effort is paying off."
        default: return "You’re thriving. Keep nurturing your wellbeing."
        }
    }
}

#Preview { NavigationStack { HomeView(selectedTab: .constant(.home)) } }

