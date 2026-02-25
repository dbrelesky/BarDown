import SwiftUI

enum AppTab: String, CaseIterable {
    case scoreboard, teams, rankings, settings

    var title: String {
        switch self {
        case .scoreboard: return "Scores"
        case .teams: return "Teams"
        case .rankings: return "Rankings"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .scoreboard: return "sportscourt.fill"
        case .teams: return "heart.fill"
        case .rankings: return "chart.bar.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .scoreboard

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(AppTab.scoreboard.title, systemImage: AppTab.scoreboard.icon, value: .scoreboard) {
                ScoreboardTab()
            }
            Tab(AppTab.teams.title, systemImage: AppTab.teams.icon, value: .teams) {
                TeamsTab()
            }
            Tab(AppTab.rankings.title, systemImage: AppTab.rankings.icon, value: .rankings) {
                RankingsTab()
            }
            Tab(AppTab.settings.title, systemImage: AppTab.settings.icon, value: .settings) {
                SettingsTab()
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}

#Preview {
    ContentView()
}
