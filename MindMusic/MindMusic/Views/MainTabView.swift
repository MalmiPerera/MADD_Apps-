import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "sparkles") }
            KaraokeView()
                .tabItem { Label("Karaoke", systemImage: "music.mic") }
            QRJoinView()
                .tabItem { Label("QR", systemImage: "qrcode") }
        }
        .tint(.teal)
    }
}

#Preview {
    MainTabView()
}
