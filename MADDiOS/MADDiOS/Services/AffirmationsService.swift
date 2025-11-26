import Foundation

// Provides short, gentle affirmations tailored to the detected EmotionState
public final class AffirmationsService {
    public static let shared = AffirmationsService()
    private init() {}

    public func affirmations(for state: EmotionState) -> [String] {
        switch state {
        case .struggling:
            return [
                "Your feelings are valid. You’re not alone.",
                "It’s okay to move slowly. Small steps count.",
                "You’ve made it through hard days before.",
                "Ask for help when you need it — that’s strength.",
                "Breathe. One moment at a time."
            ]
        case .heavy:
            return [
                "It’s heavy, and you’re still here — that matters.",
                "Be gentle with yourself today.",
                "Rest is productive when your heart is tired.",
                "You don’t have to fix everything right now.",
                "A small act of care for yourself is enough."
            ]
        case .neutral:
            return [
                "Steady is good. You’re grounded.",
                "One simple intention can shape your day.",
                "Notice one small thing you’re grateful for.",
                "Balance grows from consistent tiny actions.",
                "You’re building a foundation, one step at a time."
            ]
        case .calm:
            return [
                "Protect your peace — it nourishes you.",
                "Your calm is powerful.",
                "Savor the moments that feel easy.",
                "Share your steadiness with someone you trust.",
                "Let today be gentle and intentional."
            ]
        case .hopeful:
            return [
                "Your hope is a compass — follow it.",
                "Take one brave step toward what you want.",
                "You are allowed to grow beyond past limits.",
                "Celebrate progress, not perfection.",
                "Keep the momentum with one small action."
            ]
        }
    }
}
