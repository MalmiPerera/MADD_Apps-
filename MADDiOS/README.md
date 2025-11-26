# HealSpace (iOS)

A modern SwiftUI app for emotional wellbeing: journal with live sentiment, focus timer, HealthKit-driven insights, and visual analytics.

## Features
- Journaling with on-device sentiment analysis (NaturalLanguage)
- Focus/meditation timer with session logging
- Insights dashboard with Swift Charts (focus minutes, sentiment trends)
- Health dashboard (Steps, Active Energy, Mindful Minutes via HealthKit)
- Cohesive theme and reusable components (GlassCard, MoodChip, RecoveryGauge)

## Tech Stack
- SwiftUI (iOS 17+), NavigationStack, async/await
- Core Data (NSPersistentCloudKitContainer)
- HealthKit (read-only: Steps, Active Energy, Mindful Minutes)
- Swift Charts
- NaturalLanguage (.sentimentScore)
- Architecture: MVVM (Models, ViewModels, Views, Services, Components)

## Project Structure
- Components/: Theme, GlassCard, MoodChip, RecoveryGauge
- Services/: HealthKitService, SentimentAnalyzer
- ViewModels/: Journal, Focus, Health, Insights
- Views/: Home, Journal, Focus, Health, Insights, Settings

## How to Run
1. Open MADDiOS.xcodeproj in Xcode 15+.
2. Target iOS 17+.
3. Enable HealthKit: Target → Signing & Capabilities → + Capability → HealthKit.
4. Ensure Info.plist contains:
   - NSHealthShareUsageDescription: "HealSpace uses your activity and mindful minutes to provide wellbeing insights."
   - NSHealthUpdateUsageDescription: "HealSpace may write wellbeing-related data to your Health app in future versions."
5. Run on a real device for HealthKit data. Simulator returns sample values.

## Notes
- Sentiment uses Apple's on-device NLTagger and can be swapped for a Core ML model.
- Settings contains a theme preference (System/Light/Dark) and a daily reminder toggle (placeholder).

## Student Info
- Replace placeholders in Settings → About with your real name and student ID for submission.

## Tests
- Unit: SentimentAnalyzerTests, InsightsViewModelTests (in-memory Core Data)
- UI: Verifies main tab bar items exist and app launches
