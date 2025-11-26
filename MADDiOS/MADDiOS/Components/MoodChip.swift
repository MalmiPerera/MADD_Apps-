import SwiftUI

struct MoodChip: View {
    let state: EmotionState
    let score: Double

    var body: some View {
        HStack(spacing: 6) {
            Text(state.emoji)
            Text(label)
                .font(.caption).bold()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(state.color.opacity(0.15))
        .foregroundStyle(state.color)
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Mood \(state.rawValue), score \(String(format: "%.2f", score))")
    }

    private var label: String {
        switch state {
        case .struggling: return "Struggling"
        case .heavy: return "Heavy"
        case .neutral: return "Neutral"
        case .calm: return "Calm"
        case .hopeful: return "Happy"
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        MoodChip(state: .struggling, score: -0.8)
        MoodChip(state: .heavy, score: -0.3)
        MoodChip(state: .neutral, score: 0.0)
        MoodChip(state: .calm, score: 0.3)
        MoodChip(state: .hopeful, score: 0.8)
    }.padding()
}
