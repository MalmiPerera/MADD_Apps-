import Foundation
import CoreML
import SwiftUI

// Predicted mood improvement based on activity
struct MoodPrediction {
    let score: Double // 0-1
    let message: String
    let color: Color
    let confidence: Double
}

final class HealthMoodPredictor {
    static let shared = HealthMoodPredictor()
    private init() {}

    // Simple rule-based model (swappable for a real .mlmodel)
    func predict(
        steps: Double,
        heartRate: Double,
        activeMinutes: Double,
        previousSentiment: Double
    ) -> MoodPrediction {
        var score = 0.5 // baseline

        // Steps contribution (0-0.3)
        if steps >= 10_000 {
            score += 0.3
        } else if steps >= 7_500 {
            score += 0.2
        } else if steps >= 5_000 {
            score += 0.1
        }

        // Activity minutes (0-0.2)
        if activeMinutes >= 45 {
            score += 0.2
        } else if activeMinutes >= 30 {
            score += 0.15
        } else if activeMinutes >= 15 {
            score += 0.1
        }

        // Heart rate (-0.1 .. +0.1)
        if (60...80).contains(heartRate) {
            score += 0.1
        } else if heartRate > 90 {
            score -= 0.1
        }

        // Momentum (0-0.1)
        if previousSentiment > 0 { score += 0.1 }

        score = min(max(score, 0), 1)
        let (message, color) = generateMessage(for: score, steps: steps)
        return MoodPrediction(score: score, message: message, color: color, confidence: 0.85)
    }

    private func generateMessage(for score: Double, steps: Double) -> (String, Color) {
        switch score {
        case 0.7...1.0:
            return ("🌟 Excellent activity level! This often boosts mood significantly.", .green)
        case 0.5..<0.7:
            return ("💪 Good activity! You're on track for mood benefits.", .blue)
        case 0.3..<0.5:
            return ("🌱 Moderate activity. Try a short walk to boost mood!", .orange)
        default:
            return ("💡 Low activity today. Even 10 min of movement helps!", .yellow)
        }
    }
}
