import Foundation
import CoreML

struct HealthInsightsResult {
    let moodScore: Double
    let moodLabel: String
    let anomaly: Bool
    let recommendation: String
    let activityLabel: String
}

final class HealthInsightsService {
    static let shared = HealthInsightsService()
    private var moodModel: MLModel?
    private var anomalyModel: MLModel?
    private var activityModel: MLModel?
    private var recommendationModel: MLModel?
    private init() {
        // Try to load compiled model named "HealthMoodPredictor" if included in the app bundle
        if let url = Bundle.main.url(forResource: "HealthMoodPredictor", withExtension: "mlmodelc") {
            do {
                moodModel = try MLModel(contentsOf: url)
            } catch {
                print("[HealthInsightsService] Failed to load ML model: \(error)")
                moodModel = nil
            }
        }
        if let url = Bundle.main.url(forResource: "HealthAnomalyDetector", withExtension: "mlmodelc") {
            do { anomalyModel = try MLModel(contentsOf: url) } catch {
                print("[HealthInsightsService] Failed to load Anomaly model: \(error)")
                anomalyModel = nil
            }
        }
        if let url = Bundle.main.url(forResource: "HealthActivityClassifier", withExtension: "mlmodelc") {
            do { activityModel = try MLModel(contentsOf: url) } catch {
                print("[HealthInsightsService] Failed to load Activity model: \(error)")
                activityModel = nil
            }
        }
        if let url = Bundle.main.url(forResource: "HealthRecommender", withExtension: "mlmodelc") {
            do { recommendationModel = try MLModel(contentsOf: url) } catch {
                print("[HealthInsightsService] Failed to load Recommender model: \(error)")
                recommendationModel = nil
            }
        }
    }

    func computeInsights(steps: Double,
                         activeEnergy: Double,
                         mindfulMinutes: Double,
                         distanceKm: Double,
                         avgHeartRate: Double,
                         runningWorkouts: Int) -> HealthInsightsResult {
        // If a trained Core ML model is available, use it to predict moodScore in [-1, 1]
        let moodScore: Double
        if let model = moodModel {
            do {
                let provider = try MLDictionaryFeatureProvider(dictionary: [
                    "steps": steps as NSNumber,
                    "activeEnergy": activeEnergy as NSNumber,
                    "mindfulMinutes": mindfulMinutes as NSNumber,
                    "distanceKm": distanceKm as NSNumber,
                    "avgHeartRate": avgHeartRate as NSNumber,
                    "runningWorkouts": runningWorkouts as NSNumber
                ])
                let out = try model.prediction(from: provider)
                // Expect model to output either "moodScore" or a single numeric output
                if let val = out.featureValue(for: "moodScore")?.doubleValue {
                    moodScore = max(-1.0, min(1.0, val))
                } else if let first = out.featureNames.first,
                          let v = out.featureValue(for: first)?.doubleValue {
                    moodScore = max(-1.0, min(1.0, v))
                } else {
                    moodScore = 0
                }
            } catch {
                print("[HealthInsightsService] Model prediction failed: \(error). Falling back to heuristic.")
                moodScore = Self.heuristicMoodScore(steps: steps,
                                                    activeEnergy: activeEnergy,
                                                    mindfulMinutes: mindfulMinutes,
                                                    distanceKm: distanceKm,
                                                    avgHeartRate: avgHeartRate)
            }
        } else {
            moodScore = Self.heuristicMoodScore(steps: steps,
                                                activeEnergy: activeEnergy,
                                                mindfulMinutes: mindfulMinutes,
                                                distanceKm: distanceKm,
                                                avgHeartRate: avgHeartRate)
        }

        let moodLabel: String
        if moodScore < -0.4 { moodLabel = "struggling" }
        else if moodScore < -0.1 { moodLabel = "heavy" }
        else if moodScore <= 0.1 { moodLabel = "neutral" }
        else if moodScore < 0.5 { moodLabel = "calm" }
        else { moodLabel = "hopeful" }

        // Anomaly detection via model if available, else simple rule
        let anomaly: Bool
        if let model = anomalyModel {
            do {
                let provider = try MLDictionaryFeatureProvider(dictionary: [
                    "steps": steps as NSNumber,
                    "activeEnergy": activeEnergy as NSNumber,
                    "mindfulMinutes": mindfulMinutes as NSNumber,
                    "distanceKm": distanceKm as NSNumber,
                    "avgHeartRate": avgHeartRate as NSNumber,
                    "runningWorkouts": runningWorkouts as NSNumber
                ])
                let out = try model.prediction(from: provider)
                if let v = out.featureValue(for: "anomaly")?.int64Value {
                    anomaly = v != 0
                } else if let first = out.featureNames.first,
                          let v = out.featureValue(for: first) {
                    if v.type == .int64 { anomaly = v.int64Value != 0 }
                    else if v.type == .multiArray {
                        if let arr = v.multiArrayValue, arr.count > 0 {
                            anomaly = arr[0].intValue != 0
                        } else {
                            anomaly = false
                        }
                    }
                    else { anomaly = (v.doubleValue > 0.5) }
                } else { anomaly = false }
            } catch {
                print("[HealthInsightsService] Anomaly prediction failed: \(error). Using rule.")
                let lowActivity = steps < 2000 && activeEnergy < 150
                let elevatedHR = avgHeartRate > 90
                anomaly = lowActivity && elevatedHR
            }
        } else {
            let lowActivity = steps < 2000 && activeEnergy < 150
            let elevatedHR = avgHeartRate > 90
            anomaly = lowActivity && elevatedHR
        }

        // Activity classification via model if available (aggregate proxy); else simple rule
        let activityLabel: String
        if let model = activityModel {
            do {
                let provider = try MLDictionaryFeatureProvider(dictionary: [
                    "steps": steps as NSNumber,
                    "activeEnergy": activeEnergy as NSNumber,
                    "distanceKm": distanceKm as NSNumber,
                    "avgHeartRate": avgHeartRate as NSNumber,
                    "runningWorkouts": runningWorkouts as NSNumber
                ])
                let out = try model.prediction(from: provider)
                if let label = out.featureValue(for: "label")?.stringValue {
                    activityLabel = label
                } else if let first = out.featureNames.first,
                          let s = out.featureValue(for: first)?.stringValue {
                    activityLabel = s
                } else {
                    activityLabel = "unknown"
                }
            } catch {
                print("[HealthInsightsService] Activity classification failed: \(error). Using rule.")
                activityLabel = Self.ruleActivityLabel(steps: steps, distanceKm: distanceKm, runningWorkouts: runningWorkouts)
            }
        } else {
            activityLabel = Self.ruleActivityLabel(steps: steps, distanceKm: distanceKm, runningWorkouts: runningWorkouts)
        }

        // Recommendation via model if available, else heuristic text
        let recommendation: String
        if let model = recommendationModel {
            do {
                let provider = try MLDictionaryFeatureProvider(dictionary: [
                    "moodScore": moodScore as NSNumber,
                    "anomaly": (anomaly ? 1 : 0) as NSNumber,
                    "steps": steps as NSNumber,
                    "activeEnergy": activeEnergy as NSNumber,
                    "mindfulMinutes": mindfulMinutes as NSNumber,
                    "avgHeartRate": avgHeartRate as NSNumber
                ])
                let out = try model.prediction(from: provider)
                if let text = out.featureValue(for: "recommendation")?.stringValue {
                    recommendation = text
                } else if let first = out.featureNames.first,
                          let text = out.featureValue(for: first)?.stringValue {
                    recommendation = text
                } else {
                    recommendation = Self.heuristicRecommendation(anomaly: anomaly, mindfulMinutes: mindfulMinutes, steps: steps, avgHeartRate: avgHeartRate)
                }
            } catch {
                print("[HealthInsightsService] Recommendation prediction failed: \(error). Using heuristic.")
                recommendation = Self.heuristicRecommendation(anomaly: anomaly, mindfulMinutes: mindfulMinutes, steps: steps, avgHeartRate: avgHeartRate)
            }
        } else {
            recommendation = Self.heuristicRecommendation(anomaly: anomaly, mindfulMinutes: mindfulMinutes, steps: steps, avgHeartRate: avgHeartRate)
        }

        return HealthInsightsResult(moodScore: moodScore,
                                    moodLabel: moodLabel,
                                    anomaly: anomaly,
                                    recommendation: recommendation,
                                    activityLabel: activityLabel)
    }

    private static func heuristicMoodScore(steps: Double,
                                           activeEnergy: Double,
                                           mindfulMinutes: Double,
                                           distanceKm: Double,
                                           avgHeartRate: Double) -> Double {
        let normSteps = min(max(steps / 10000.0, 0), 1)
        let normEnergy = min(max(activeEnergy / 600.0, 0), 1)
        let normMindful = min(max(mindfulMinutes / 20.0, 0), 1)
        let normDistance = min(max(distanceKm / 8.0, 0), 1)
        let hrScore = 1.0 - min(max((avgHeartRate - 50.0) / 60.0, 0), 1)

        let score = (0.35 * normSteps) + (0.25 * normEnergy) + (0.2 * normMindful) + (0.1 * normDistance) + (0.1 * hrScore)
        return (score * 2.0) - 1.0
    }

    private static func ruleActivityLabel(steps: Double, distanceKm: Double, runningWorkouts: Int) -> String {
        if runningWorkouts > 0 || distanceKm >= 1.0 { return "running/walking" }
        if steps > 8000 { return "active" }
        if steps > 3000 { return "light" }
        return "sedentary"
    }

    private static func heuristicRecommendation(anomaly: Bool, mindfulMinutes: Double, steps: Double, avgHeartRate: Double) -> String {
        if anomaly { return "Take a short mindful break and a gentle 10–15 min walk to rebalance." }
        if mindfulMinutes < 5 { return "Try 3 minutes of breathing to reset." }
        if steps < 6000 { return "A brief walk could lift energy today." }
        if avgHeartRate > 85 { return "Keep intensity light and hydrate." }
        return "Great balance today. Keep it up!"
    }
}
