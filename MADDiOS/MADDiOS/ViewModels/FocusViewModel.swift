import Foundation
import CoreData
import UIKit
import Combine

@MainActor
final class FocusViewModel: ObservableObject {
    @Published var seconds: Int = 0
    @Published var isRunning: Bool = false
    @Published var note: String = ""
    @Published var averageSessionDuration: Int32 = 0
    @Published var totalSessions: Int = 0
    @Published var longestSession: Int32 = 0
    @Published var currentStreak: Int = 0
    @Published var motivationalMessage: String = ""

    private var tickerTask: Task<Void, Never>?

    func start() {
        guard !isRunning else { return }
        isRunning = true
        tickerTask = Task { [weak self] in
            while let self, !Task.isCancelled, self.isRunning {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { break }
                await MainActor.run { self.seconds += 1 }
            }
        }
    }

    func pause() {
        isRunning = false
        tickerTask?.cancel()
        tickerTask = nil
    }

    func reset() {
        pause()
        seconds = 0
        note = ""
    }

    func completeSession(context: NSManagedObjectContext, noteOverride: String? = nil) {
        pause()
        let session = FocusSession(context: context)
        session.id = UUID()
        session.start = Date().addingTimeInterval(TimeInterval(-seconds))
        session.end = Date()
        session.durationSeconds = Int32(seconds)
        let finalNote = noteOverride ?? note
        session.note = finalNote.isEmpty ? nil : finalNote
        do { try context.save() } catch { print("[FocusVM] save error: \(error)") }
        calculateStats(context: context)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        reset()
    }

    // MARK: - Stats
    func calculateStats(context: NSManagedObjectContext) {
        let sessions = fetchAllSessions(context: context)
        guard !sessions.isEmpty else {
            averageSessionDuration = 0
            totalSessions = 0
            longestSession = 0
            currentStreak = 0
            return
        }
        totalSessions = sessions.count
        let total = sessions.reduce(0) { $0 + Int($1.durationSeconds) }
        averageSessionDuration = Int32(total / sessions.count)
        longestSession = sessions.map { $0.durationSeconds }.max() ?? 0
        currentStreak = calculateStreak(from: sessions)
    }

    private func fetchAllSessions(context: NSManagedObjectContext) -> [FocusSession] {
        let req: NSFetchRequest<FocusSession> = FocusSession.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(key: "end", ascending: false)]
        return (try? context.fetch(req)) ?? []
    }

    // Calculate consecutive days of focus sessions
    private func calculateStreak(from sessions: [FocusSession]) -> Int {
        let sortedByDate = sessions.sorted { ($0.start ?? Date()) > ($1.start ?? Date()) }
        var streak = 0
        var currentDate = Calendar.current.startOfDay(for: Date())
        for session in sortedByDate {
            guard let sessionDate = session.start else { continue }
            let sessionDay = Calendar.current.startOfDay(for: sessionDate)
            let dayDiff = Calendar.current.dateComponents([.day], from: sessionDay, to: currentDate).day ?? 0
            if dayDiff == 0 || dayDiff == 1 {
                if dayDiff == 1 {
                    streak += 1
                    currentDate = sessionDay
                }
            } else {
                break
            }
        }
        return max(streak, sessions.isEmpty ? 0 : 1) // count today as day 1 when applicable
    }

    // Generate motivational message comparing to previous session
    func getMotivationalMessage(for duration: Int, context: NSManagedObjectContext) -> String {
        let sessions = fetchAllSessions(context: context)
        guard sessions.count > 1 else {
            return "Great job completing your first focus session! 🎉"
        }
        let previousSession = sessions[1] // Most recent before current
        let previousDuration = Int(previousSession.durationSeconds)
        guard previousDuration > 0 else { return "Nice work showing up today! 🌱" }
        let difference = duration - previousDuration
        let percentChange = Double(difference) / Double(previousDuration) * 100
        if difference > 60 {
            return "Amazing! You focused \(difference/60) min longer than last time! 🚀"
        } else if difference > 0 {
            return "Nice! You improved by \(difference) seconds (\(String(format: "%.0f", percentChange))%). Keep building! 💪"
        } else if difference == 0 {
            return "Consistent! Same duration as last time. You're building a habit! ⭐"
        } else if abs(difference) < 120 {
            return "Good session! Sometimes shorter focus is okay. What matters is showing up! 🌱"
        } else {
            return "Every session counts! Let's try to beat your \(previousDuration/60)-min record next time 🎯"
        }
    }

    // Check if this is a personal record
    func isPersonalRecord(duration: Int) -> Bool { return Int32(duration) > longestSession }
}
