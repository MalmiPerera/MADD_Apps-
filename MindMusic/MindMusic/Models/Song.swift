import Foundation

struct LyricLine: Identifiable, Hashable {
    let id = UUID()
    let timestamp: TimeInterval
    let text: String
}

struct Song: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let artist: String
    let duration: TimeInterval
    let lyrics: [LyricLine]
    let altLyrics: [LyricLine]?

    static let samples: [Song] = [
        Song(
            title: "Calm River",
            artist: "MindMusic",
            duration: 120,
            lyrics: [
                .init(timestamp: 0, text: "Breathe in, breathe out"),
                .init(timestamp: 5, text: "Let the river carry doubt"),
                .init(timestamp: 10, text: "Clouds drift, worries fade"),
                .init(timestamp: 15, text: "You are safe, unafraid"),
                .init(timestamp: 25, text: "Feel the calm surround"),
                .init(timestamp: 35, text: "Heart in gentle sound")
            ],
            altLyrics: [
                .init(timestamp: 0, text: "Gentle breath, settle slow"),
                .init(timestamp: 5, text: "Let the steady currents flow"),
                .init(timestamp: 10, text: "Every ripple, easing strain"),
                .init(timestamp: 15, text: "Resting mind, soft as rain")
            ]
        ),
        Song(
            title: "Soft Sunrise",
            artist: "MindMusic",
            duration: 130,
            lyrics: [
                .init(timestamp: 0, text: "Golden light, softly bright"),
                .init(timestamp: 6, text: "Warming soul, easing night"),
                .init(timestamp: 12, text: "Every breath, a gentle start"),
                .init(timestamp: 18, text: "Opening windows of the heart")
            ],
            altLyrics: [
                .init(timestamp: 0, text: "Morning glow, kind and clear"),
                .init(timestamp: 6, text: "Whispered hope drawing near"),
                .init(timestamp: 12, text: "Rise with peace, softly true"),
                .init(timestamp: 18, text: "Sky of calm surrounding you")
            ]
        ),
        Song(
            title: "Ocean Hush",
            artist: "MindMusic",
            duration: 110,
            lyrics: [
                .init(timestamp: 0, text: "Waves arrive, then retreat"),
                .init(timestamp: 7, text: "Find your steady beat"),
                .init(timestamp: 14, text: "Listen close, quietly"),
                .init(timestamp: 22, text: "Rest in present, peacefully")
            ],
            altLyrics: nil
        )
    ]
}
