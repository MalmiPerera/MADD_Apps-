import Foundation
import CoreData

final class HealthDataExporterService {
    static let shared = HealthDataExporterService()
    private init() {}

    func generateCSV(days: Int,
                     context: NSManagedObjectContext) async throws -> URL {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let start = cal.date(byAdding: .day, value: -days + 1, to: today)!

        var moodByDay: [Date: Double] = [:]
        do {
            let req: NSFetchRequest<JournalEntry> = JournalEntry.fetchRequest()
            // Fetch between start and end
            let end = cal.date(byAdding: .day, value: 1, to: today)!
            req.predicate = NSPredicate(format: "(date >= %@) AND (date < %@)", start as NSDate, end as NSDate)
            if let entries = try? context.fetch(req) {
                var buckets: [Date: [Double]] = [:]
                for e in entries {
                    guard let d = e.date else { continue }
                    let day = cal.startOfDay(for: d)
                    buckets[day, default: []].append(e.sentimentScore)
                }
                for (k, arr) in buckets { moodByDay[k] = arr.isEmpty ? 0 : (arr.reduce(0, +) / Double(arr.count)) }
            }
        }

        var csv = "date,steps,activeEnergy,mindfulMinutes,distanceKm,avgHeartRate,runningWorkouts,moodScore_label,anomaly_label\n"
        for i in 0..<days {
            guard let day = cal.date(byAdding: .day, value: i, to: start) else { continue }
            do {
                async let steps = HealthKitService.shared.fetchStepCount(on: day)
                async let energy = HealthKitService.shared.fetchActiveEnergy(on: day)
                async let mindful = HealthKitService.shared.fetchMindfulMinutes(on: day)
                async let distance = HealthKitService.shared.fetchDistanceKilometers(on: day)
                async let heart = HealthKitService.shared.fetchAverageHeartRate(on: day)
                async let runs = HealthKitService.shared.fetchRunningWorkoutsCount(on: day)
                let (s, e, m, dKm, h, r) = try await (steps, energy, mindful, distance, heart, runs)

                let mood = moodByDay[day] ?? 0
                let lowActivity = s < 2000 && e < 150
                let elevatedHR = h > 90
                let anomaly = (lowActivity && elevatedHR) ? 1 : 0

                let dateStr = ISO8601DateFormatter().string(from: day)
                let row = String(format: "%@,%.0f,%.0f,%.0f,%.3f,%.0f,%d,%.4f,%d\n", dateStr, s, e, m, dKm, h, r, mood, anomaly)
                csv.append(row)
            } catch {
                continue
            }
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("health_export_\(days)d.csv")
        try csv.data(using: .utf8)?.write(to: url)
        return url
    }
}
