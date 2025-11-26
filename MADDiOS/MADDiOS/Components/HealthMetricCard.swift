import SwiftUI

struct HealthMetricCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let progress: Double?
    let color: Color

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.title)
                        .foregroundStyle(color)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                        Text(value)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                    }

                    Spacer()
                }

                if let p = progress {
                    ProgressView(value: min(max(p, 0), 1))
                        .tint(color)
                }

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
