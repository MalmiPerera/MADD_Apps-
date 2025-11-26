import SwiftUI

struct WeeklySummaryCard: View {
    @ObservedObject var viewModel: HealthViewModel

    var body: some View {
        GlassCard(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Weekly Summary")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "calendar")
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 16) {
                    summaryItem(
                        icon: "figure.walk",
                        title: "Steps",
                        value: Int(viewModel.todaySteps),
                        goal: 56000, // 8k x 7
                        tint: .blue
                    )
                    summaryItem(
                        icon: "flame.fill",
                        title: "Active",
                        value: Int(viewModel.todayActiveMinutes),
                        goal: 210, // 30 x 7
                        tint: .orange
                    )
                    summaryItem(
                        icon: "heart.fill",
                        title: "HR Avg",
                        value: Int(viewModel.todayAverageHeartRate),
                        goal: 75, // illustrative target
                        tint: .red
                    )
                }
            }
        }
    }

    private func summaryItem(icon: String, title: String, value: Int, goal: Int, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(tint)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("\(value)")
                .font(.headline)
            ProgressView(value: min(max(Double(value) / Double(goal), 0), 1))
                .tint(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    WeeklySummaryCard(viewModel: HealthViewModel(service: HealthKitService.shared))
        .padding()
        .background(LinearGradient(colors: Theme.bgGradient, startPoint: .topLeading, endPoint: .bottomTrailing))
}
