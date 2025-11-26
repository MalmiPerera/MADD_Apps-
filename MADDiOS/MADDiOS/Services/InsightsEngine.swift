import Foundation
import CoreData
import SwiftUI

struct RecoveryScore {
    let overall: Double // 0-100
    let emotional: Double // Sentiment-based
    let behavioral: Double // Focus-based
    let physical: Double // Activity-based
    let trend: RecoveryTrend

    enum RecoveryTrend {
        case improving // ↗️
        case stable // →
        case declining // ↘️
    }
}

struct Insight {
    let id = UUID()
    let title: String
    let description: String
    let category: InsightCategory
    let icon: String
    let color: Color

    enum InsightCategory {
        case celebration // Positive achievements
        case pattern // Discovered correlations
        case recommendation // Actionable suggestions
        case milestone // Important achievements
    }
}

final class InsightsEngine {
    static let shared = InsightsEngine()

    // Calculate recovery score from all data sources
    func calculateRecoveryScore(
        journalEntries: [JournalEntry],
        focusSessions: [FocusSession],
        healthMetrics: (steps: Double, heartRate: Double, activeMinutes: Double)
    ) -> RecoveryScore {

        // 1. EMOTIONAL HEALTH (40% weight)
        let emotionalScore = calculateEmotionalScore(from: journalEntries)

        // 2. BEHAVIORAL HEALTH (30% weight)
        let behavioralScore = calculateBehavioralScore(from: focusSessions)

        // 3. PHYSICAL HEALTH (30% weight)
        let physicalScore = calculatePhysicalScore(from: healthMetrics)

        // Weighted average
        let overall = (emotionalScore * 0.4) + (behavioralScore * 0.3) + (physicalScore * 0.3)

        // Determine trend
        let trend = determineTrend(
            journalEntries: journalEntries,
            focusSessions: focusSessions
        )

        return RecoveryScore(
            overall: overall,
            emotional: emotionalScore,
            behavioral: behavioralScore,
            physical: physicalScore,
            trend: trend
        )
    }

    private func calculateEmotionalScore(from entries: [JournalEntry]) -> Double {
        guard !entries.isEmpty else { return 50.0 }

        // Get last 7 days
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let recentEntries = entries.filter { ($0.date ?? Date()) >= sevenDaysAgo }

        guard !recentEntries.isEmpty else { return 50.0 }

        // Average sentiment: -1 to 1 → convert to 0-100
        let avgSentiment = recentEntries.reduce(0.0) { $0 + $1.sentimentScore } / Double(recentEntries.count)

        // Map -1...1 to 0...100
        return ((avgSentiment + 1) / 2) * 100
    }

    private func calculateBehavioralScore(from sessions: [FocusSession]) -> Double {
        guard !sessions.isEmpty else { return 30.0 }

        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let recentSessions = sessions.filter { ($0.start ?? Date()) >= sevenDaysAgo }

        guard !recentSessions.isEmpty else { return 30.0 }

        // Factors: consistency (40%), duration (60%)

        // Consistency: How many days out of 7?
        let uniqueDays = Set(recentSessions.compactMap {
            Calendar.current.startOfDay(for: $0.start ?? Date())
        }).count
        let consistencyScore = (Double(uniqueDays) / 7.0) * 40

        // Duration: Average duration vs. 20-min target
        let avgDuration = recentSessions.reduce(0) { $0 + $1.durationSeconds } / Int32(recentSessions.count)
        let durationScore = min(Double(avgDuration) / (20 * 60), 1.0) * 60

        return consistencyScore + durationScore
    }

    private func calculatePhysicalScore(from metrics: (steps: Double, heartRate: Double, activeMinutes: Double)) -> Double {
        var score = 0.0

        // Steps (50% of physical score)
        let stepsScore = min(metrics.steps / 10000, 1.0) * 50
        score += stepsScore

        // Heart Rate (20% - optimal range 60-80)
        let hrScore: Double
        if metrics.heartRate >= 60 && metrics.heartRate <= 80 {
            hrScore = 20
        } else if metrics.heartRate > 0 {
            hrScore = 10
        } else {
            hrScore = 0
        }
        score += hrScore

        // Active Minutes (30%)
        let activeScore = min(metrics.activeMinutes / 30, 1.0) * 30
        score += activeScore

        return score
    }

    private func determineTrend(
        journalEntries: [JournalEntry],
        focusSessions: [FocusSession]
    ) -> RecoveryScore.RecoveryTrend {

        // Compare this week vs last week sentiment
        let now = Date()
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: now)!

        let thisWeekEntries = journalEntries.filter {
            ($0.date ?? Date()) >= oneWeekAgo
        }

        let lastWeekEntries = journalEntries.filter {
            let date = $0.date ?? Date()
            return date >= twoWeeksAgo && date < oneWeekAgo
        }

        guard !thisWeekEntries.isEmpty, !lastWeekEntries.isEmpty else {
            return .stable
        }

        let thisWeekAvg = thisWeekEntries.reduce(0.0) { $0 + $1.sentimentScore } / Double(thisWeekEntries.count)
        let lastWeekAvg = lastWeekEntries.reduce(0.0) { $0 + $1.sentimentScore } / Double(lastWeekEntries.count)

        let change = thisWeekAvg - lastWeekAvg

        if change > 0.15 {
            return .improving
        } else if change < -0.15 {
            return .declining
        } else {
            return .stable
        }
    }

    // Generate personalized insights
    func generateInsights(
        recoveryScore: RecoveryScore,
        journalEntries: [JournalEntry],
        focusSessions: [FocusSession],
        healthMetrics: (steps: Double, heartRate: Double)
    ) -> [Insight] {

        var insights: [Insight] = []

        // 1. Overall recovery celebration/concern
        if recoveryScore.overall >= 70 {
            insights.append(Insight(
                title: "Strong Recovery Progress! 🌟",
                description: "Your overall recovery score is \(Int(recoveryScore.overall))/100. You're doing great!",
                category: .celebration,
                icon: "star.fill",
                color: .green
            ))
        } else if recoveryScore.overall >= 50 {
            insights.append(Insight(
                title: "Steady Progress 💪",
                description: "You're at \(Int(recoveryScore.overall))/100. Keep building those healthy habits!",
                category: .celebration,
                icon: "chart.line.uptrend.xyaxis",
                color: .blue
            ))
        }

        // 2. Trend insight
        switch recoveryScore.trend {
        case .improving:
            insights.append(Insight(
                title: "Upward Trajectory! ↗️",
                description: "Your mood has improved this week compared to last. This is excellent progress!",
                category: .celebration,
                icon: "arrow.up.right",
                color: .green
            ))
        case .declining:
            insights.append(Insight(
                title: "Gentle Reminder 💙",
                description: "Things seem a bit harder this week. Remember: recovery isn't linear. Be kind to yourself.",
                category: .recommendation,
                icon: "heart.fill",
                color: .orange
            ))
        case .stable:
            break
        }

        // 3. Journal consistency
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let recentEntries = journalEntries.filter { ($0.date ?? Date()) >= sevenDaysAgo }

        if recentEntries.count >= 5 {
            insights.append(Insight(
                title: "Journaling Streak! 📝",
                description: "You've journaled \(recentEntries.count) times this week. Consistency builds resilience!",
                category: .milestone,
                icon: "book.fill",
                color: .purple
            ))
        } else if recentEntries.count == 0 {
            insights.append(Insight(
                title: "Try Journaling 📖",
                description: "You haven't journaled this week. Writing helps process emotions and track progress.",
                category: .recommendation,
                icon: "pencil",
                color: .blue
            ))
        }

        // 4. Activity-mood correlation (simplified heuristic)
        if healthMetrics.steps > 8_000 {
            let positiveDays = journalEntries.filter { $0.sentimentScore > 0 }
            if !positiveDays.isEmpty {
                insights.append(Insight(
                    title: "Activity = Mood Boost! 🚶‍♀️",
                    description: "You tend to feel better on days with 8,000+ steps. Keep moving!",
                    category: .pattern,
                    icon: "figure.walk",
                    color: .green
                ))
            }
        }

        // 5. Focus session milestone
        let totalSessions = focusSessions.count
        if totalSessions >= 10 {
            insights.append(Insight(
                title: "10+ Focus Sessions! 🎯",
                description: "You've completed \(totalSessions) focus sessions. Meditation builds mental resilience.",
                category: .milestone,
                icon: "target",
                color: .indigo
            ))
        }

        return insights
    }
}
