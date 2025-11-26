import SwiftUI

struct HomeView: View {
    @State private var isPlaying = false
    @State private var progress: Double = 0
    @State private var breathIn = true
    @State private var timer: Timer?

    var body: some View {
        ZStack {
            LinearGradient(colors: [.teal.opacity(0.5), .indigo.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("MindMusic")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                    Text("Find your calm. Breathe and listen.")
                        .foregroundStyle(.white.opacity(0.9))
                }

                ZStack {
                    Circle()
                        .fill(.white.opacity(0.1))
                        .frame(width: 240, height: 240)
                        .blur(radius: 2)
                    Circle()
                        .strokeBorder(.white.opacity(0.25), lineWidth: 1)
                        .frame(width: 260, height: 260)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(AngularGradient(gradient: Gradient(colors: [.mint, .cyan, .indigo]), center: .center), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 220, height: 220)
                        .animation(.easeInOut(duration: 0.6), value: progress)

                    VStack(spacing: 8) {
                        Text(breathIn ? "Breathe In" : "Breathe Out")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                        Text(isPlaying ? "Session in progress" : "Tap play to begin")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }

                HStack(spacing: 28) {
                    Button {
                        progress = 0
                        stopTimer()
                        isPlaying = false
                    } label: {
                        controlIcon("backward.fill")
                    }

                    Button {
                        isPlaying.toggle()
                        isPlaying ? startTimer() : stopTimer()
                    } label: {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 72, height: 72)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(.white.opacity(0.25), lineWidth: 1))
                    }

                    Button {
                        progress = min(progress + 0.1, 1)
                    } label: {
                        controlIcon("forward.fill")
                    }
                }

                VStack(spacing: 6) {
                    Text("Ambient: Ocean Hush")
                        .foregroundStyle(.white)
                    ProgressView(value: progress)
                        .tint(.mint)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .padding()
        }
        .onDisappear { stopTimer() }
    }

    private func controlIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 52, height: 52)
            .background(.ultraThinMaterial)
            .clipShape(Circle())
            .overlay(Circle().stroke(.white.opacity(0.25), lineWidth: 1))
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            progress += 0.02
            if progress >= 1 { progress = 0 }
            breathIn.toggle()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

#Preview {
    HomeView()
}
