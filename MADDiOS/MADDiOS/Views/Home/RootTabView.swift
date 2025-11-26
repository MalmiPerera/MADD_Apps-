import SwiftUI

struct RootTabView: View {
    enum AppTab: Hashable { case home, journal, focus, health, insights, settings }
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack { HomeView(selectedTab: $selectedTab) }
                .tabItem { Label("Home", systemImage: "house") }
                .tag(AppTab.home)

            NavigationStack { JournalListView() }
                .tabItem { Label("Journal", systemImage: "book.closed") }
                .tag(AppTab.journal)

            NavigationStack { FocusView() }
                .tabItem { Label("Focus", systemImage: "timer") }
                .tag(AppTab.focus)

            NavigationStack { HealthDashboardView() }
                .tabItem { Label("Health", systemImage: "heart.fill") }
                .tag(AppTab.health)

            NavigationStack { InsightsView() }
                .tabItem { Label("Insights", systemImage: "chart.bar.xaxis") }
                .tag(AppTab.insights)

            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(AppTab.settings)
        }
        .tint(Theme.accent)
    }
}

#Preview { RootTabView() }
