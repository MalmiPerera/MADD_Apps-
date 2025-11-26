import XCTest
@testable import MADDiOS

final class SentimentAnalyzerTests: XCTestCase {
    func testNegativeTextMapsToHeavyOrStruggling() {
        let text = "I feel terrible, empty, and hopeless. Nothing seems to work."
        let score = SentimentAnalyzer.shared.score(for: text)
        let emotion = SentimentAnalyzer.shared.emotion(for: score)
        XCTAssertTrue([.heavy, .struggling].contains(emotion), "Expected heavy/struggling for negative text, got \(emotion)")
    }

    func testPositiveTextMapsToCalmOrHopeful() {
        let text = "I feel great, grateful, and optimistic about my progress!"
        let score = SentimentAnalyzer.shared.score(for: text)
        let emotion = SentimentAnalyzer.shared.emotion(for: score)
        XCTAssertTrue([.calm, .hopeful].contains(emotion), "Expected calm/hopeful for positive text, got \(emotion)")
    }

    func testThresholdEmotionMapping() {
        XCTAssertEqual(SentimentAnalyzer.shared.emotion(for: -0.8), .struggling)
        XCTAssertEqual(SentimentAnalyzer.shared.emotion(for: -0.2), .heavy)
        XCTAssertEqual(SentimentAnalyzer.shared.emotion(for: 0.0), .neutral)
        XCTAssertEqual(SentimentAnalyzer.shared.emotion(for: 0.3), .calm)
        XCTAssertEqual(SentimentAnalyzer.shared.emotion(for: 0.8), .hopeful)
    }
}
