import SwiftUI
import CoreData

struct JournalEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context

    let entry: JournalEntry

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
                                        let combined = (newValue + "\n" + bodyText)
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
                                        let combined = (title + "\n" + newValue)
                                        score = SentimentAnalyzer.shared.score(for: combined)
                                    }
                            }
                        }

                        GlassCard {
                            HStack {
                                let state = SentimentAnalyzer.shared.emotion(for: score)
                                MoodChip(state: state, score: score)
                                Spacer()
                                Text(sentimentLabel(for: state))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Entry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { withAnimation { dismiss() } }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Update") {
                        withAnimation(.spring()) {
                            applyUpdate()
                            showSuccess = true
                        }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear {
            title = entry.title ?? ""
            bodyText = entry.text ?? ""
            score = SentimentAnalyzer.shared.score(for: (title + "\n" + bodyText))
        }
        .alert("Journal updated successfully.", isPresented: $showSuccess) {
            Button("OK") { dismiss() }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func applyUpdate() {
        entry.title = title.isEmpty ? "Untitled" : title
        entry.text = bodyText
        entry.date = entry.date ?? Date()
        entry.sentimentScore = SentimentAnalyzer.shared.score(for: bodyText)
        do { try context.save() } catch { print("[JournalEdit] save error: \(error)") }
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

#Preview {
    let container = PersistenceController.shared.container
    let ctx = container.viewContext
    let e = JournalEntry(context: ctx)
    e.id = UUID(); e.date = Date(); e.title = "A day"; e.text = "Feeling okay"; e.sentimentScore = 0.1
    return JournalEditView(entry: e).environment(\.managedObjectContext, ctx)
}
