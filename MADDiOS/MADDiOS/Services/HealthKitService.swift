import Foundation
import HealthKit

// MARK: - HealthKitService
final class HealthKitService {
    static let shared = HealthKitService()
    private let healthStore = HKHealthStore()

    // MARK: Authorization
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        var readTypes = Set<HKObjectType>()
        if let steps = HKObjectType.quantityType(forIdentifier: .stepCount) { readTypes.insert(steps) }
        if let energy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) { readTypes.insert(energy) }
        if let mindful = HKObjectType.categoryType(forIdentifier: .mindfulSession) { readTypes.insert(mindful) }
        if let distance = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) { readTypes.insert(distance) }
        if let heart = HKObjectType.quantityType(forIdentifier: .heartRate) { readTypes.insert(heart) }
        readTypes.insert(HKObjectType.workoutType())
        try await healthStore.requestAuthorization(toShare: [], read: readTypes)
    }

    // MARK: Helpers
    private func todayPredicate() -> NSPredicate {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end = cal.date(byAdding: .day, value: 1, to: start)!
        return HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
    }

    private func dayPredicate(for date: Date) -> NSPredicate {
        let cal = Calendar.current
        let start = cal.startOfDay(for: date)
        let end = cal.date(byAdding: .day, value: 1, to: start)!
        return HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
    }

    private func isHKAvailable() -> Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    private func sampleReturn(_ value: Double, label: String) -> Double {
        print("[HealthKitService] Using sample value for \(label) (simulator or unavailable)")
        return value
    }

    // MARK: Queries
    func fetchTodayStepCount() async throws -> Double {
        guard isHKAvailable(), let type = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            return sampleReturn(6000, label: "steps")
        }
        let predicate = todayPredicate()
        return try await withCheckedThrowingContinuation { cont in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, error in
                if let error = error { cont.resume(throwing: error); return }
                let value = stats?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                cont.resume(returning: value)
            }
            self.healthStore.execute(query)
        }
    }

    func fetchTodayActiveEnergy() async throws -> Double {
        guard isHKAvailable(), let type = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return sampleReturn(350, label: "activeEnergy")
        }
        let predicate = todayPredicate()
        return try await withCheckedThrowingContinuation { cont in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, error in
                if let error = error { cont.resume(throwing: error); return }
                let value = stats?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                cont.resume(returning: value)
            }
            self.healthStore.execute(query)
        }
    }

    func fetchTodayMindfulMinutes() async throws -> Double {
        guard isHKAvailable(), let type = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
            return sampleReturn(12, label: "mindfulMinutes")
        }
        let predicate = todayPredicate()
        return try await withCheckedThrowingContinuation { cont in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                if let error = error { cont.resume(throwing: error); return }
                let totalMinutes = (samples as? [HKCategorySample])?.reduce(0.0) { acc, s in
                    acc + s.endDate.timeIntervalSince(s.startDate) / 60.0
                } ?? 0
                cont.resume(returning: totalMinutes)
            }
            self.healthStore.execute(query)
        }
    }

    func fetchTodayDistanceKilometers() async throws -> Double {
        guard isHKAvailable(), let type = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) else {
            return sampleReturn(3.2, label: "distanceKm")
        }
        let predicate = todayPredicate()
        return try await withCheckedThrowingContinuation { cont in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, error in
                if let error = error { cont.resume(throwing: error); return }
                let meters = stats?.sumQuantity()?.doubleValue(for: .meter()) ?? 0
                cont.resume(returning: meters / 1000.0)
            }
            self.healthStore.execute(query)
        }
    }

    // Average heart rate for today (bpm)
    func fetchTodayAverageHeartRate() async throws -> Double {
        guard isHKAvailable(), let type = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            return sampleReturn(72, label: "heartRate")
        }
        let predicate = todayPredicate()
        return try await withCheckedThrowingContinuation { cont in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .discreteAverage) { _, stats, error in
                if let error = error { cont.resume(throwing: error); return }
                let unit = HKUnit.count().unitDivided(by: .minute())
                let bpm = stats?.averageQuantity()?.doubleValue(for: unit) ?? 0
                cont.resume(returning: bpm)
            }
            self.healthStore.execute(query)
        }
    }

    // Count of running workouts today
    func fetchTodayRunningWorkoutsCount() async throws -> Int {
        guard isHKAvailable() else { return Int(sampleReturn(1, label: "runCount")) }
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            todayPredicate(),
            HKQuery.predicateForWorkouts(with: .running)
        ])
        return try await withCheckedThrowingContinuation { cont in
            let query = HKSampleQuery(sampleType: .workoutType(), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                if let error = error { cont.resume(throwing: error); return }
                let count = (samples as? [HKWorkout])?.count ?? 0
                cont.resume(returning: count)
            }
            self.healthStore.execute(query)
        }
    }

    // MARK: Per-day Queries (for historical export)
    func fetchStepCount(on date: Date) async throws -> Double {
        guard isHKAvailable(), let type = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            return sampleReturn(6000, label: "steps")
        }
        let predicate = dayPredicate(for: date)
        return try await withCheckedThrowingContinuation { cont in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, error in
                if let error = error { cont.resume(throwing: error); return }
                let value = stats?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                cont.resume(returning: value)
            }
            self.healthStore.execute(query)
        }
    }

    func fetchActiveEnergy(on date: Date) async throws -> Double {
        guard isHKAvailable(), let type = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return sampleReturn(350, label: "activeEnergy")
        }
        let predicate = dayPredicate(for: date)
        return try await withCheckedThrowingContinuation { cont in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, error in
                if let error = error { cont.resume(throwing: error); return }
                let value = stats?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                cont.resume(returning: value)
            }
            self.healthStore.execute(query)
        }
    }

    func fetchMindfulMinutes(on date: Date) async throws -> Double {
        guard isHKAvailable(), let type = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
            return sampleReturn(12, label: "mindfulMinutes")
        }
        let predicate = dayPredicate(for: date)
        return try await withCheckedThrowingContinuation { cont in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                if let error = error { cont.resume(throwing: error); return }
                let totalMinutes = (samples as? [HKCategorySample])?.reduce(0.0) { acc, s in
                    acc + s.endDate.timeIntervalSince(s.startDate) / 60.0
                } ?? 0
                cont.resume(returning: totalMinutes)
            }
            self.healthStore.execute(query)
        }
    }

    func fetchDistanceKilometers(on date: Date) async throws -> Double {
        guard isHKAvailable(), let type = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) else {
            return sampleReturn(3.2, label: "distanceKm")
        }
        let predicate = dayPredicate(for: date)
        return try await withCheckedThrowingContinuation { cont in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, error in
                if let error = error { cont.resume(throwing: error); return }
                let meters = stats?.sumQuantity()?.doubleValue(for: .meter()) ?? 0
                cont.resume(returning: meters / 1000.0)
            }
            self.healthStore.execute(query)
        }
    }

    func fetchAverageHeartRate(on date: Date) async throws -> Double {
        guard isHKAvailable(), let type = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            return sampleReturn(72, label: "heartRate")
        }
        let predicate = dayPredicate(for: date)
        return try await withCheckedThrowingContinuation { cont in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .discreteAverage) { _, stats, error in
                if let error = error { cont.resume(throwing: error); return }
                let unit = HKUnit.count().unitDivided(by: .minute())
                let bpm = stats?.averageQuantity()?.doubleValue(for: unit) ?? 0
                cont.resume(returning: bpm)
            }
            self.healthStore.execute(query)
        }
    }

    func fetchRunningWorkoutsCount(on date: Date) async throws -> Int {
        guard isHKAvailable() else { return Int(sampleReturn(1, label: "runCount")) }
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            dayPredicate(for: date),
            HKQuery.predicateForWorkouts(with: .running)
        ])
        return try await withCheckedThrowingContinuation { cont in
            let query = HKSampleQuery(sampleType: .workoutType(), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                if let error = error { cont.resume(throwing: error); return }
                let count = (samples as? [HKWorkout])?.count ?? 0
                cont.resume(returning: count)
            }
            self.healthStore.execute(query)
        }
    }
}
