import SwiftUI

// Scale on tap
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// Shimmer loading effect
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -200
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [.clear, .white.opacity(0.35), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .rotationEffect(.degrees(25))
                .offset(x: phase)
                .blendMode(.plusLighter)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 600
                }
            }
    }
}

extension View {
    func shimmer() -> some View { modifier(ShimmerModifier()) }
}

// Slide in from bottom
struct SlideInModifier: ViewModifier {
    let delay: Double
    @State private var isVisible = false
    func body(content: Content) -> some View {
        content
            .offset(y: isVisible ? 0 : 40)
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(.spring().delay(delay)) { isVisible = true }
            }
    }
}

extension View {
    func slideIn(delay: Double = 0) -> some View { modifier(SlideInModifier(delay: delay)) }
}
