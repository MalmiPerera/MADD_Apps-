import SwiftUI

struct KaraokeView: View {
    @State private var songs = Song.samples
    @State private var selection = 0
    @State private var useAltLyrics = false
    @State private var playTime: TimeInterval = 0
    @State private var isPlaying = false
    @State private var timer: Timer?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                TabView(selection: $selection) {
                    ForEach(Array(songs.enumerated()), id: \.offset) { index, song in
                        songPage(song)
                            .tag(index)
                            .padding(.horizontal)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .onChange(of: selection) { _ in resetPlayback() }
                playerControls
            }
            .background(
                LinearGradient(colors: [.purple.opacity(0.25), .blue.opacity(0.25)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            )
        }
    }

    private var header: some View {
        HStack {
            Text("Karaoke")
                .font(.title2.bold())
            Spacer()
            Menu {
                Button(useAltLyrics ? "Use Original" : "Use Alt Lyrics") {
                    useAltLyrics.toggle()
                }
            } label: {
                Label("Lyrics", systemImage: "text.quote")
            }
        }
        .padding([.horizontal, .top])
    }

    private func songPage(_ song: Song) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title).font(.title.bold())
                Text(song.artist).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(activeLyrics(for: song)) { line in
                            let active = isActive(line: line)
                            Text(line.text)
                                .font(.title3.weight(active ? .bold : .regular))
                                .foregroundStyle(active ? .primary : .secondary)
                                .padding(.vertical, 4)
                                .id(line.id)
                                .animation(.easeInOut(duration: 0.2), value: active)
                        }
                    }
                    .onChange(of: playTime) { _ in
                        if let current = currentLine(in: activeLyrics(for: song)) {
                            withAnimation { proxy.scrollTo(current.id, anchor: .center) }
                        }
                    }
                }
                .frame(maxHeight: 320)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            Spacer(minLength: 8)
        }
    }

    private var playerControls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                Button { prevSong() } label: { controlIcon("backward.fill") }
                Button {
                    isPlaying.toggle()
                    isPlaying ? startTimer() : stopTimer()
                } label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.primary)
                        .frame(width: 64, height: 44)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                Button { nextSong() } label: { controlIcon("forward.fill") }
            }
            .padding(.top, 12)

            ProgressView(value: min(playTime, currentSong.duration), total: currentSong.duration)
                .tint(.mint)
                .padding(.horizontal)
                .animation(.linear(duration: 0.25), value: playTime)
        }
        .padding(.bottom, 16)
    }

    private func controlIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(.primary)
            .frame(width: 44, height: 44)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var currentSong: Song { songs[selection] }

    private func activeLyrics(for song: Song) -> [LyricLine] {
        useAltLyrics ? (song.altLyrics ?? song.lyrics) : song.lyrics
    }

    private func isActive(line: LyricLine) -> Bool {
        let next = activeLyrics(for: currentSong).first { $0.timestamp > line.timestamp }
        let end = next?.timestamp ?? (currentSong.duration)
        return playTime >= line.timestamp && playTime < end
    }

    private func currentLine(in lyrics: [LyricLine]) -> LyricLine? {
        lyrics.last { $0.timestamp <= playTime }
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            playTime += 0.5
            if playTime >= currentSong.duration { playTime = 0 }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func resetPlayback() {
        stopTimer()
        playTime = 0
        if isPlaying { startTimer() }
    }

    private func prevSong() { selection = (selection - 1 + songs.count) % songs.count }
    private func nextSong() { selection = (selection + 1) % songs.count }
}

#Preview { KaraokeView() }
