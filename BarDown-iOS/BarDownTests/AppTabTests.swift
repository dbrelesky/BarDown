import Testing
@testable import BarDown

@Suite("AppTab Enum")
struct AppTabTests {

    @Test("Has exactly four cases")
    func caseCount() {
        #expect(AppTab.allCases.count == 4)
    }

    @Test("Cases are in correct order")
    func caseOrder() {
        let expected: [AppTab] = [.scoreboard, .teams, .rankings, .settings]
        #expect(AppTab.allCases == expected)
    }

    @Test("Raw values match case names")
    func rawValues() {
        #expect(AppTab.scoreboard.rawValue == "scoreboard")
        #expect(AppTab.teams.rawValue == "teams")
        #expect(AppTab.rankings.rawValue == "rankings")
        #expect(AppTab.settings.rawValue == "settings")
    }

    @Test("Titles are user-facing display strings",
          arguments: [
            (AppTab.scoreboard, "Scores"),
            (AppTab.teams, "Teams"),
            (AppTab.rankings, "Rankings"),
            (AppTab.settings, "Settings"),
          ])
    func titles(tab: AppTab, expected: String) {
        #expect(tab.title == expected)
    }

    @Test("Icons are valid SF Symbol names",
          arguments: [
            (AppTab.scoreboard, "sportscourt.fill"),
            (AppTab.teams, "heart.fill"),
            (AppTab.rankings, "chart.bar.fill"),
            (AppTab.settings, "gearshape.fill"),
          ])
    func icons(tab: AppTab, expected: String) {
        #expect(tab.icon == expected)
    }

    @Test("Default selected tab is scoreboard")
    func defaultTab() {
        #expect(AppTab.allCases.first == .scoreboard)
    }
}
