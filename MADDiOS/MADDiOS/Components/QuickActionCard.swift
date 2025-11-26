import SwiftUI

struct QuickActionCard: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            GlassCard(padding: 20) {
                VStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 32))
                        .foregroundStyle(color)
                    Text(title)
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
