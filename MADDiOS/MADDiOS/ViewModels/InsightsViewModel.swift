import Foundation
import CoreData
import Combine

public struct DailyPoint: Identifiable {
    public let id = UUID()
    public let date: Date
    public let value: Double
}

public enum InsightsRange: CaseIterable { case week, month }

@MainActor
final class InsightsViewModel: ObservableObject {
    @Published var recoveryScore: RecoveryScore?
    @Published var insights: [Insight] = []
    @Published var isLoading = false

    func refreshInsights(context: NSManagedObjectContext, healthMetrics: (steps: Double, heartRate: Double, activeMinutes: Double)) {
        isLoading = true

        // Fetch journal entries
        let journalRequest: NSFetchRequest<JournalEntry> = JournalEntry.fetchRequest()
        journalRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        // Fetch focus sessions
        let focusRequest: NSFetchRequest<FocusSession> = FocusSession.fetchRequest()
        focusRequest.sortDescriptors = [NSSortDescriptor(key: "start", ascending: false)]

        do {
            let entries = try context.fetch(journalRequest)
            let sessions = try context.fetch(focusRequest)

            // Calculate recovery score
            recoveryScore = InsightsEngine.shared.calculateRecoveryScore(
                journalEntries: entries,
                focusSessions: sessions,
                healthMetrics: healthMetrics
            )

            // Generate insights
            if let score = recoveryScore {
                insights = InsightsEngine.shared.generateInsights(
                    recoveryScore: score,
                    journalEntries: entries,
                    focusSessions: sessions,
                    healthMetrics: (healthMetrics.steps, healthMetrics.heartRate)
                )
            }

        } catch {
            print("Error fetching data for insights: \(error)")
        }

        isLoading = false
    }

    // MARK: - Aggregations
    var dailyFocusMinutes: [DailyPoint] {
        aggregate(byMinutes: true)
    }

    var dailyAverageSentiment: [DailyPoint] {
        aggregate(byMinutes: false)
    }

    // A simple composite score (0..100) combining normalized sentiment, focus minutes, and mindful minutes
    var recoveryScore: Int {
        // sentiment avg (-1..1) -> (0..100)
        let sentimentAvg = entries.isEmpty ? 0 : entries.map { $0.sentimentScore }.reduce(0, +) / Double(entries.count)
        let sentimentComponent = (sentimentAvg + 1) / 2 * 100 // map -1..1 to 0..100

        // focus total minutes in range, capped to 60 min/day equivalent
        let focusTotal = dailyFocusMinutes.map { $0.value }.reduce(0, +)
        let focusComponent = min(focusTotal, 60 * Double(windowDays)) / Double(60 * windowDays) * 100

        // mindful minutes today, capped to 20
        let mindfulComponent = min(todayMindfulMinutes, 20) / 20 * 100

        let combined = (sentimentComponent * 0.5) + (focusComponent * 0.3) + (mindfulComponent * 0.2)
        return Int(round(combined))
    }

    // MARK: - Helpers
    private var windowDays: Int { range == .week ? 7 : 30 }

    private func aggregate(byMinutes: Bool) -> [DailyPoint] {
        let cal = Calendar.current
        let now = Date()
        let start = cal.date(byAdding: .day, value: -windowDays + 1, to: cal.startOfDay(for: now))!

        // Initialize buckets for each day
        var buckets: [Date: [Double]] = [:]
        for i in 0..<windowDays {
            if let day = cal.date(byAdding: .day, value: i, to: start) {
                buckets[day] = []
            }
        }

        if byMinutes {
            // Sum focus minutes per day
            for s in sessions {
                guard let startDate = s.start else { continue }
                let day = cal.startOfDay(for: startDate)
                if buckets[day] != nil {
                    buckets[day, default: []].append(Double(s.durationSeconds) / 60.0)
                }
            }
            return buckets.keys.sorted().map { d in
                DailyPoint(date: d, value: buckets[d]?.reduce(0, +) ?? 0)
            }
        } else {
            // Average sentiment per day
            var scoreByDay: [Date: [Double]] = [:]
            for e in entries {
                guard let date = e.date else { continue }
                let day = cal.startOfDay(for: date)
                scoreByDay[day, default: []].append(e.sentimentScore)
            }
            return buckets.keys.sorted().map { d in
                let arr = scoreByDay[d] ?? []
                let avg = arr.isEmpty ? 0 : arr.reduce(0, +) / Double(arr.count)
                return DailyPoint(date: d, value: avg)
            }
        }
    }
}
