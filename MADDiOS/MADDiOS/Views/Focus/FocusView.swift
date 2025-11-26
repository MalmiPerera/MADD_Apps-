import SwiftUI
import CoreData

struct FocusView: View {
    @Environment(\.managedObjectContext) private var context
    @StateObject private var viewModel = FocusViewModel()
    @State private var showSavedBanner = false
    @State private var showCompletion = false
    @State private var completionDuration: Int = 0
    @State private var completionNote: String = ""
    @State private var completionMessage: String = ""

    // Simple progress: cap at one hour for UI (0...1)
    private var progress: CGFloat {
        let cap = 3600.0
        return CGFloat(min(Double(viewModel.seconds) / cap, 1.0))
    }

    var body: some View {
        ZStack(alignment: .top) {
            LinearGradient(colors: Theme.bgGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    GlassCard {
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .trim(from: 0, to: 1)
                                    .stroke(Color.secondary.opacity(0.15), style: StrokeStyle(lineWidth: 16, lineCap: .round))
                                    .rotationEffect(.degrees(-90))
                                Circle()
                                    .trim(from: 0, to: progress)
                                    .stroke(Theme.accent, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                                    .rotationEffect(.degrees(-90))
                                    .animation(.easeInOut(duration: 0.25), value: viewModel.seconds)
                                Text(formatTime(viewModel.seconds))
                                    .font(.system(size: 36, weight: .semibold, design: .rounded).monospacedDigit())
                            }
                            .frame(width: 240, height: 240)

                            TextField("What are you focusing on?", text: $viewModel.note)
                                .textFieldStyle(.roundedBorder)
                        }
                    }

                    GlassCard {
                        HStack(spacing: 12) {
                            Button(viewModel.isRunning ? "Pause" : "Start") {
                                viewModel.isRunning ? viewModel.pause() : viewModel.start()
                            }
                            .buttonStyle(.borderedProminent)
                            .scaleEffect(viewModel.isRunning ? 1.0 : 1.02)
                            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.isRunning)

                            Button("Reset") { viewModel.reset() }
                                .buttonStyle(.bordered)

                            Button("Complete") {
                                viewModel.pause()
                                completionDuration = viewModel.seconds
                                completionNote = viewModel.note
                                // Calculate stats BEFORE saving current session
                                viewModel.calculateStats(context: context)
                                completionMessage = viewModel.getMotivationalMessage(for: completionDuration, context: context)
                                showCompletion = true
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .onAppear { viewModel.calculateStats(context: context) }

            if showSavedBanner {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    Text("Session saved")
                        .font(.subheadline).bold()
                }
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .shadow(radius: 8)
                .transition(.move(edge: .top).combined(with: .opacity))
                .padding(.top, 12)
            }
        }
        .navigationTitle("Focus")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink("History") { FocusHistoryView() }
            }
        }
        .sheet(isPresented: $showCompletion) {
            NavigationStack {
                VStack(spacing: 16) {
                    Text("Session Complete")
                        .font(.title2).bold()
                    Text(formatTime(completionDuration))
                        .font(.system(size: 36, weight: .semibold, design: .rounded))
                    Text(completionMessage)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("Your Average", systemImage: "chart.bar"); Spacer(); Text("\(viewModel.averageSessionDuration/60) min")
                            }
                            HStack {
                                Label("Personal Best", systemImage: "star.fill"); Spacer(); Text("\(viewModel.longestSession/60) min")
                            }
                            HStack {
                                Label("Streak", systemImage: "flame.fill"); Spacer(); Text("\(viewModel.currentStreak) days 🔥")
                            }
                        }
                    }

                    TextField("Add a note (optional)", text: $completionNote)
                        .textFieldStyle(.roundedBorder)

                    Button("Complete Session") {
                        viewModel.completeSession(context: context, noteOverride: completionNote)
                        withAnimation(.spring()) { showSavedBanner = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                            withAnimation(.easeInOut) { showSavedBanner = false }
                        }
                        showCompletion = false
                    }
                    .buttonStyle(.borderedProminent)

                    Spacer(minLength: 0)
                }
                .padding()
                .navigationTitle("Summary")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 { return String(format: "%02d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }
}

#Preview { NavigationStack { FocusView() } }
