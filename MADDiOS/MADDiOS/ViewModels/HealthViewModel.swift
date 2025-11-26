import Foundation
import Combine

@MainActor
final class HealthViewModel: ObservableObject {
    @Published var isAuthorized: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    @Published var todaySteps: Double = 0
    @Published var todayActiveEnergy: Double = 0
    @Published var todayMindfulMinutes: Double = 0
    @Published var todayDistanceKm: Double = 0
    @Published var todayAverageHeartRate: Double = 0
    @Published var todayRunningWorkouts: Int = 0
    @Published var moodScore: Double = 0
    @Published var moodLabel: String = "neutral"
    @Published var anomaly: Bool = false
    @Published var recommendation: String = ""
    @Published var activityLabel: String = "unknown"
    @Published var todayActiveMinutes: Double = 0
    @Published var moodPrediction: MoodPrediction?

    private let service: HealthKitService
    private let insights = HealthInsightsService.shared

    init(service: HealthKitService) {
        self.service = service
    }

    func requestAuthorization() async {
        do {
            try await service.requestAuthorization()
            isAuthorized = true
        } catch {
            isAuthorized = false
            errorMessage = error.localizedDescription
        }
    }

    func refreshToday() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let steps = service.fetchTodayStepCount()
            async let energy = service.fetchTodayActiveEnergy()
            async let mindful = service.fetchTodayMindfulMinutes()
            async let distance = service.fetchTodayDistanceKilometers()
            async let heart = service.fetchTodayAverageHeartRate()
            async let runs = service.fetchTodayRunningWorkoutsCount()
            let (s, e, m, d, h, r) = try await (steps, energy, mindful, distance, heart, runs)
            todaySteps = s
            todayActiveEnergy = e
            todayMindfulMinutes = m
            todayDistanceKm = d
            todayAverageHeartRate = h
            todayRunningWorkouts = r

            let result = insights.computeInsights(
                steps: s,
                activeEnergy: e,
                mindfulMinutes: m,
                distanceKm: d,
                avgHeartRate: h,
                runningWorkouts: r
            )
            moodScore = result.moodScore
            moodLabel = result.moodLabel
            anomaly = result.anomaly
            recommendation = result.recommendation
            activityLabel = result.activityLabel
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshWithPrediction(previousSentiment: Double) async {
        await refreshToday()
        todayActiveMinutes = todayActiveEnergy / 5.0
        let prediction = HealthMoodPredictor.shared.predict(
            steps: todaySteps,
            heartRate: todayAverageHeartRate,
            activeMinutes: todayActiveMinutes,
            previousSentiment: previousSentiment
        )
        moodPrediction = prediction
    }
}
