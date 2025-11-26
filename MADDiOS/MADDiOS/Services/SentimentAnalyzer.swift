import Foundation
import NaturalLanguage
import SwiftUI

// MARK: - EmotionState
// Simple buckets derived from sentiment score [-1, 1]
public enum EmotionState: String, CaseIterable {
    case struggling
    case heavy
    case neutral
    case calm
    case hopeful

    // Emoji representation to surface the feeling quickly in UI
    public var emoji: String {
        switch self {
        case .struggling: return "💔"
        case .heavy:      return "😞"
        case .neutral:    return "😐"
        case .calm:       return "🙂"
        case .hopeful:    return "🌈"
        }
    }

    // A suggested accent color for UI elements associated to this state
    public var color: Color {
        switch self {
        case .struggling: return Theme.rose.opacity(0.95)
        case .heavy:      return Theme.petal
        case .neutral:    return Theme.sand
        case .calm:       return Theme.blush
        case .hopeful:    return Theme.accent
        }
    }
}

// MARK: - SentimentAnalyzer
// Uses Apple's NaturalLanguage on-device ML (NLTagger with .sentimentScore)
// This can be swapped to a Core ML model later by loading an NLModel/MLModel and
// mapping its classification/score to the same [-1, 1] scale used below.
public final class SentimentAnalyzer {
    public static let shared = SentimentAnalyzer()
    private init() {}

    // Returns a score in [-1, 1] where negative is sad/heavy and positive is calm/hopeful
    public func score(for text: String) -> Double {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let preview = String(trimmed.prefix(50))
        print("🧠 [SentimentAnalyzer] Analyzing text: '\(preview)...'")
        guard !trimmed.isEmpty else {
            print("   ⚠️ Empty text, returning 0")
            return 0
        }
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = trimmed
        let (tag, _) = tagger.tag(at: trimmed.startIndex, unit: .paragraph, scheme: .sentimentScore)
        if let raw = tag?.rawValue, let val = Double(raw) {
            let state = emotion(for: val)
            print("   ✅ Sentiment score: \(val) → \(state.rawValue)")
            return val
        }
        return 0
    }

    // Maps the numeric score to an EmotionState bucket for UI
    public func emotion(for score: Double) -> EmotionState {
        switch score {
        case ..<(-0.4): return .struggling
        case -0.4..<(-0.1): return .heavy
        case -0.1...0.1: return .neutral
        case 0.1..<0.5: return .calm
        default: return .hopeful
        }
    }

    // Convenience helpers if you prefer functional-style usage
    public func emoji(for score: Double) -> String { emotion(for: score).emoji }
    public func color(for score: Double) -> Color { emotion(for: score).color }
}
