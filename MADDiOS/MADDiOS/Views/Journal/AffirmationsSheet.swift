import SwiftUI

struct AffirmationsSheet: View {
    let mood: EmotionState
    var onDone: () -> Void

    private var titleText: String {
        switch mood {
        case .struggling: return "Gentle support"
        case .heavy: return "Soft encouragement"
        case .neutral: return "Steady and grounded"
        case .calm: return "Keep your calm"
        case .hopeful: return "Nurture the hope"
        }
    }

    private var affirmations: [String] {
        AffirmationsService.shared.affirmations(for: mood)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: Theme.bgGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        GlassCard {
                            HStack(spacing: 12) {
                                Text(mood.emoji)
                                    .font(.system(size: 44))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(titleText)
                                        .font(.headline)
                                    Text("You seem \(mood.rawValue). Here are some affirmations for you.")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                        }

                        VStack(spacing: 12) {
                            ForEach(affirmations, id: \.self) { line in
                                GlassCard {
                                    HStack(alignment: .top, spacing: 10) {
                                        Image(systemName: "sparkle")
                                            .foregroundStyle(Theme.accent)
                                        Text(line)
                                            .font(.body)
                                            .multilineTextAlignment(.leading)
                                        Spacer()
                                    }
                                }
                            }
                        }

                        Button(action: onDone) {
                            Text("Done")
                                .bold()
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
            }
            .navigationTitle("Affirmations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { onDone() }
                }
            }
        }
    }
}

#Preview {
    AffirmationsSheet(mood: .calm) {}
}
