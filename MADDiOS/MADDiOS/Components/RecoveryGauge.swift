import SwiftUI

struct RecoveryGauge: View {
    let value: Double // 0...100
    var title: String = "Recovery"
    var subtitle: String? = nil

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .trim(from: 0, to: 1)
                    .stroke(Color.secondary.opacity(0.15), style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Circle()
                    .trim(from: 0, to: CGFloat(min(max(value/100, 0), 1)))
                    .stroke(Theme.success, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.6), value: value)
                Text("\(Int(value))%")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
            }
            .frame(width: 140, height: 140)

            Text(title).font(.headline)
            if let subtitle { Text(subtitle).font(.caption).foregroundStyle(.secondary) }
        }
    }
}

#Preview {
    RecoveryGauge(value: 72, title: "Recovery", subtitle: "Composite wellbeing score")
        .padding()
}
