import SwiftUI

enum AppTab: String, CaseIterable {
    case scoreboard, teams, rankings, settings

    var title: String {
        switch self {
        case .scoreboard: return "Scores"
        case .teams: return "Teams"
        case .rankings: return "Rankings"
        case .settings: return "More"
        }
    }

    var icon: String {
        switch self {
        case .scoreboard: return "list.bullet.rectangle.portrait.fill"
        case .teams: return "person.2.fill"
        case .rankings: return "trophy.fill"
        case .settings: return "line.3.horizontal"
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
        .tint(Color(red: 0.31, green: 0.92, blue: 0.56))
    }
}

#Preview {
    ContentView()
}
