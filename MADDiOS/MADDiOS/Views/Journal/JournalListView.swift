import SwiftUI
import CoreData

struct JournalListView: View {
    @Environment(\.managedObjectContext) private var context
    @StateObject private var viewModel = JournalViewModel()
    @State private var showingCompose = false
    @State private var showDeleteSuccess = false

    var body: some View {
        ZStack {
            LinearGradient(colors: Theme.bgGradient, startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            if viewModel.entries.isEmpty {
                VStack(spacing: 12) {
                    Text("No journal entries yet")
                        .font(.headline)
                    Text("Tap the + button to write your first reflection.")
                        .foregroundStyle(.secondary)
                }
                .padding()
            } else {
                List {
                    ForEach(viewModel.entries, id: \.objectID) { entry in
                        NavigationLink(destination: JournalDetailView(entry: entry)) {
                            let score = entry.sentimentScore
                            let state = SentimentAnalyzer.shared.emotion(for: score)
                            GlassCard {
                                HStack(alignment: .top) {
                                    Text(state.emoji)
                                        .font(.title2)
                                        .padding(.trailing, 4)
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack(spacing: 6) {
                                            Text(entry.title ?? "Untitled").font(.headline)
                                            if score < -0.6 { Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange).font(.caption) }
                                        }
                                        Text((entry.date ?? Date()), style: .date)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text((entry.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines))
                                            .font(.subheadline)
                                            .lineLimit(3)
                                            .foregroundStyle(.primary)
                                        Text(suggestion(for: state))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    MoodChip(state: state, score: score)
                                }
                            }
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                    .onDelete { idx in
                        idx.map { viewModel.entries[$0] }.forEach { viewModel.delete($0, context: context) }
                        showDeleteSuccess = true
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }

            // FAB
            VStack { Spacer() }
                .overlay(alignment: .bottomTrailing) {
                    Button {
                        withAnimation(.spring()) { showingCompose = true }
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .padding(18)
                            .background(Circle().fill(Theme.accent))
                            .shadow(radius: 10)
                    }
                    .padding(20)
                }
        }
        .navigationTitle("Journal")
        .onAppear { viewModel.fetch(context: context) }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Debug: Test Entry") {
                    let ts = Date().formatted(date: .abbreviated, time: .standard)
                    viewModel.addEntry(title: "Debug Entry (\(ts))", text: "This is a quick debug note to verify Core Data save & fetch.", context: context)
                }
            }
        }
        .sheet(isPresented: $showingCompose) {
            JournalComposeView(viewModel: viewModel)
                .environment(\.managedObjectContext, context)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .alert("Journal deleted successfully.", isPresented: $showDeleteSuccess) {
            Button("OK") {}
        }
    }
}

private struct JournalDetailView: View {
    let entry: JournalEntry
    @State private var showEdit = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(entry.title ?? "Untitled").font(.title2).bold()
                Text((entry.date ?? Date()), style: .date).foregroundStyle(.secondary)
                let score = entry.sentimentScore
                let state = SentimentAnalyzer.shared.emotion(for: score)
                MoodChip(state: state, score: score)
                GlassCard {
                    HStack(alignment: .top) {
                        Image(systemName: "lightbulb.fill").foregroundStyle(.yellow)
                        Text(suggestion(for: state)).font(.subheadline)
                    }
                }
                Text(entry.text ?? "").font(.body)
            }
            .padding()
        }
        .navigationTitle("Entry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showEdit = true }
            }
        }
        .navigationDestination(isPresented: $showEdit) {
            JournalEditView(entry: entry)
        }
    }
}

#Preview { NavigationStack { JournalListView() } }

private func suggestion(for state: EmotionState) -> String {
    switch state {
    case .struggling:
        return "Heavy feelings are valid. Try a 5‑minute breath, then write one small thing you can do next."
    case .heavy:
        return "Name the feeling and take a short walk. A tiny action can shift the day."
    case .neutral:
        return "You’re steady. Consider noting one gratitude or intention for today."
    case .calm:
        return "Grounded energy. Protect it with a short focus session or mindful minute."
    case .hopeful:
        return "Great momentum. Capture a goal and schedule a 15‑minute step toward it."
    }
}
