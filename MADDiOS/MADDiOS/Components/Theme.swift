import SwiftUI

// MARK: - Theme
// These Color names should exist in your Asset catalog with light/dark variants
// (e.g. primary, background, card, danger, success)
struct Theme {
    static let primary = Color("primary")
    static let background = Color("background")
    static let card = Color("card")
    static let danger = Color("danger")
    static let success = Color("success")

    // Pink/Beige aesthetic palette
    static let blush = Color(red: 1.0, green: 0.82, blue: 0.86)        // #FFD1DB
    static let rose = Color(red: 0.98, green: 0.67, blue: 0.76)         // #FCAABB
    static let petal = Color(red: 0.95, green: 0.79, blue: 0.82)        // #F2C9D1
    static let beige = Color(red: 0.98, green: 0.94, blue: 0.90)        // #FAF0E6
    static let sand = Color(red: 0.96, green: 0.90, blue: 0.86)         // #F5E6DB

    // App accent for buttons, tabs, charts
    static let accent = Color(red: 0.96, green: 0.49, blue: 0.62)       // #F67D9E

    // Background gradient used across screens
    static var bgGradient: [Color] {
        [beige.opacity(0.9), blush.opacity(0.7)]
    }

    // Modern gradients
    static var cardGradient: LinearGradient {
        LinearGradient(
            colors: [Color.white.opacity(0.2), Color.white.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [accent, accent.opacity(0.7)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    // Shadows
    static var cardShadow: Color { Color.black.opacity(0.1) }

    // Corner radius
    static let cornerRadiusSmall: CGFloat = 12
    static let cornerRadiusMedium: CGFloat = 16
    static let cornerRadiusLarge: CGFloat = 24

    // Spacing
    static let spacingXS: CGFloat = 4
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 16
    static let spacingL: CGFloat = 24
    static let spacingXL: CGFloat = 32
}

// MARK: - Typography helpers
extension Font {
    static var titleStyle: Font { .largeTitle.weight(.semibold) }
    static var headlineStyle: Font { .title2.weight(.semibold) }
}
