import SwiftUI
import CoreData

struct JournalComposeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context

    @ObservedObject var viewModel: JournalViewModel

    @State private var title: String = ""
    @State private var bodyText: String = ""
    @State private var score: Double = 0
    @State private var showSuccess: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: Theme.bgGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                TextField("Title", text: $title)
                                    .textFieldStyle(.roundedBorder)
                                    .onChange(of: title) { _, newValue in
                                        let combined = newValue + "\n" + bodyText
                                        score = SentimentAnalyzer.shared.score(for: combined)
                                    }
                                TextEditor(text: $bodyText)
                                    .frame(minHeight: 180)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.secondary.opacity(0.2))
                                    )
                                    .overlay(alignment: .topTrailing) {
                                        let state = SentimentAnalyzer.shared.emotion(for: score)
                                        Text(state.emoji)
                                            .font(.title2)
                                            .padding(8)
                                            .background(.ultraThinMaterial, in: Capsule())
                                            .padding(8)
                                    }
                                    .onChange(of: bodyText) { _, newValue in
                                        let combined = title + "\n" + newValue
                                        score = SentimentAnalyzer.shared.score(for: combined)
                                    }
                            }
                        }

                        MoodPreview(score: score)
                    }
                    .padding()
                }
            }
            .navigationTitle("New Entry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { withAnimation { dismiss() } }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        withAnimation(.spring()) {
                            viewModel.addEntry(title: title.isEmpty ? "Untitled" : title, text: bodyText, context: context)
                            showSuccess = true
                        }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear {
            score = SentimentAnalyzer.shared.score(for: (title + "\n" + bodyText))
        }
        .alert("Journal saved successfully.", isPresented: $showSuccess) {
            Button("OK") { dismiss() }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func sentimentLabel(for state: EmotionState) -> String {
        switch state {
        case .struggling: return "It hurts now — honest and brave."
        case .heavy: return "Heavy but honest."
        case .neutral: return "Balanced reflection."
        case .calm: return "Grounded and calm."
        case .hopeful: return "Hopeful and growing."
        }
    }
}

// Local suggestion helper used by MoodPreview in this file
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

#Preview {
    let container = PersistenceController.shared.container
    let vm = JournalViewModel()
    return JournalComposeView(viewModel: vm).environment(\.managedObjectContext, container.viewContext)
}

// MARK: - MoodPreview
private struct MoodPreview: View {
    let score: Double
    private var state: EmotionState { SentimentAnalyzer.shared.emotion(for: score) }
    private var normalized: CGFloat { CGFloat(max(0, min(1, (score + 1.0) / 2.0))) }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 12) {
                    Text(state.emoji)
                        .font(.system(size: 42))
                        .scaleEffect(1.0 + 0.05 * normalized)
                        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: score)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Feeling \(state.rawValue.capitalized)")
                            .font(.headline)
                        Text(String(format: "Score: %.2f", score))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                // Score bar -1 to +1 mapped to 0...1
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.secondary.opacity(0.15))
                        Capsule()
                            .fill(state.color)
                            .frame(width: geo.size.width * normalized)
                            .animation(.easeInOut(duration: 0.25), value: score)
                    }
                }
                .frame(height: 10)

                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill").foregroundStyle(.yellow)
                    Text(suggestion(for: state))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
            .tint(state.color)
        }
    }
}
