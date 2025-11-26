import SwiftUI
import CoreData
import Charts

struct InsightsView: View {
    @Environment(\.managedObjectContext) private var context
    @StateObject private var viewModel = InsightsViewModel()
    @StateObject private var healthViewModel = HealthViewModel(service: HealthKitService.shared)

    var body: some View {
        ZStack {
            LinearGradient(colors: Theme.bgGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    if let score = viewModel.recoveryScore {
                        RecoveryScoreCard(score: score)
                    }

                    if !viewModel.insights.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Personalized Insights")
                                .font(.headline)
                                .padding(.horizontal)
                            ForEach(viewModel.insights, id: \.id) { insight in
                                InsightCard(insight: insight)
                            }
                        }
                    }

                    if let score = viewModel.recoveryScore {
                        ScoreBreakdownCard(score: score)
                    }
                }
                .padding()
            }
            .refreshable { await refreshData() }

            if viewModel.isLoading { ProgressView() }
        }
        .navigationTitle("Recovery Insights")
        .task { await refreshData() }
    }

    private func refreshData() async {
        await healthViewModel.refreshToday()
        viewModel.refreshInsights(
            context: context,
            healthMetrics: (
                steps: healthViewModel.todaySteps,
                heartRate: healthViewModel.todayAverageHeartRate,
                activeMinutes: healthViewModel.todayActiveEnergy / 5
            )
        )
    }
}

// Recovery Score Card Component
struct RecoveryScoreCard: View {
    let score: RecoveryScore

    var body: some View {
        GlassCard {
            VStack(spacing: 16) {
                Text("Recovery Score").font(.headline)

                ZStack {
                    Circle().stroke(Color.white.opacity(0.2), lineWidth: 20)
                    Circle()
                        .trim(from: 0, to: score.overall / 100)
                        .stroke(
                            LinearGradient(colors: [scoreColor, scoreColor.opacity(0.6)], startPoint: .leading, endPoint: .trailing),
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(), value: score.overall)
                    VStack {
                        Text("\(Int(score.overall))").font(.system(size: 48, weight: .bold, design: .rounded))
                        Text("out of 100").font(.caption).foregroundStyle(.secondary)
                        HStack(spacing: 4) {
                            Image(systemName: trendIcon)
                            Text(trendText)
                        }
                        .font(.caption)
                        .foregroundStyle(trendColor)
                    }
                }
                .frame(height: 200)

                Text(scoreMessage)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var scoreColor: Color {
        switch score.overall {
        case 70...100: return .green
        case 50..<70: return .blue
        case 30..<50: return .orange
        default: return .red
        }
    }

    private var scoreMessage: String {
        switch score.overall {
        case 70...100: return "You're doing wonderfully! Your recovery journey is strong."
        case 50..<70: return "Solid progress! You're building healthy patterns."
        case 30..<50: return "Keep going! Every small step forward counts."
        default: return "Be gentle with yourself. Recovery takes time and patience."
        }
    }

    private var trendIcon: String {
        switch score.trend {
        case .improving: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .declining: return "arrow.down.right"
        }
    }

    private var trendText: String {
        switch score.trend {
        case .improving: return "Improving"
        case .stable: return "Stable"
        case .declining: return "Needs attention"
        }
    }

    private var trendColor: Color {
        switch score.trend {
        case .improving: return .green
        case .stable: return .blue
        case .declining: return .orange
        }
    }
}

// Insight Card Component
struct InsightCard: View {
    let insight: Insight

    var body: some View {
        GlassCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: insight.icon).font(.title2).foregroundStyle(insight.color)
                VStack(alignment: .leading, spacing: 4) {
                    Text(insight.title).font(.headline)
                    Text(insight.description).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
    }
}

// Score Breakdown Card
struct ScoreBreakdownCard: View {
    let score: RecoveryScore

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Score Breakdown").font(.headline)
                ScoreBar(title: "Emotional Health", score: score.emotional, color: .purple)
                ScoreBar(title: "Behavioral Health", score: score.behavioral, color: .blue)
                ScoreBar(title: "Physical Health", score: score.physical, color: .green)
            }
        }
    }
}

struct ScoreBar: View {
    let title: String
    let score: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).font(.subheadline)
                Spacer()
                Text("\(Int(score))").font(.subheadline).bold()
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.2))
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(score / 100))
                        .animation(.spring(), value: score)
                }
            }
            .frame(height: 8)
        }
    }
}

#Preview {
    NavigationStack { InsightsView() }
}
