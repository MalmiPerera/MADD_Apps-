import SwiftUI
import CoreData

struct HealthDashboardView: View {
    // Emerging technology integration: HealthKit via HealthViewModel + HealthKitService
    @StateObject private var viewModel = HealthViewModel(service: HealthKitService.shared)
    @State private var didBootstrap = false
    @Environment(\.managedObjectContext) private var context
    @State private var exportURL: URL?
    @State private var exporting: Bool = false
    @State private var showShare: Bool = false

    var body: some View {
        ScrollViewReader { proxy in
        ZStack {
            LinearGradient(colors: Theme.bgGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    Color.clear.frame(height: 1).id("top")
                    if let error = viewModel.errorMessage {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 6) {
                                Label("Health permissions needed", systemImage: "exclamationmark.triangle")
                                    .font(.headline)
                                Text(error).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }

                    // Header with ML prediction
                    GlassCard {
                        VStack(spacing: 12) {
                            Text("Today's Activity").font(.headline)
                            if let prediction = viewModel.moodPrediction {
                                HStack {
                                    Image(systemName: "brain.head.profile").font(.title2)
                                    VStack(alignment: .leading) {
                                        Text("Mood Outlook").font(.caption)
                                        Text(prediction.message).font(.subheadline).bold()
                                    }
                                    Spacer()
                                }
                                .foregroundStyle(prediction.color)
                            }
                        }
                    }

                    // Metric 1: Steps
                    HealthMetricCard(
                        icon: "figure.walk",
                        title: "Steps Today",
                        value: "\(Int(viewModel.todaySteps))",
                        subtitle: "Goal: 8,000",
                        progress: min(viewModel.todaySteps / 8000, 1.0),
                        color: .blue
                    )

                    // Metric 2: Heart Rate
                    HealthMetricCard(
                        icon: "heart.fill",
                        title: "Avg Heart Rate",
                        value: "\(Int(viewModel.todayAverageHeartRate)) bpm",
                        subtitle: "Resting: 60-80 bpm",
                        progress: nil,
                        color: .red
                    )

                    // Metric 3: Active Minutes
                    HealthMetricCard(
                        icon: "flame.fill",
                        title: "Active Minutes",
                        value: "\(Int(viewModel.todayActiveMinutes))",
                        subtitle: "Goal: 30 min",
                        progress: min(max(viewModel.todayActiveMinutes / 30, 0), 1.0),
                        color: .orange
                    )

                    WeeklySummaryCard(viewModel: viewModel)
                }
                .padding()
            }
            .refreshable {
                await viewModel.refreshWithPrediction(previousSentiment: 0)
            }

            if viewModel.isLoading {
                ProgressView().controlSize(.large)
            }
        }
        .navigationTitle("Health")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        exporting = true
                        defer { exporting = false }
                        do {
                            let url = try await HealthDataExporterService.shared.generateCSV(days: 60, context: context)
                            exportURL = url
                            showShare = true
                        } catch {
                            print("[HealthDashboard] Export error: \(error)")
                        }
                    }
                } label: {
                    if exporting {
                        ProgressView()
                    } else {
                        Label("Export 60d CSV", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
        .sheet(isPresented: $showShare, onDismiss: { exportURL = nil }) {
            if let url = exportURL {
                ShareLink(item: url) { Label("Share CSV", systemImage: "square.and.arrow.up") }
                    .padding()
            } else {
                Text("Preparing export...")
                    .padding()
            }
        }
        .task {
            guard !didBootstrap else { return }
            didBootstrap = true
            await viewModel.requestAuthorization()
            await viewModel.refreshWithPrediction(previousSentiment: 0)
        }
        }
    }
}

#Preview { NavigationStack { HealthDashboardView() } }

