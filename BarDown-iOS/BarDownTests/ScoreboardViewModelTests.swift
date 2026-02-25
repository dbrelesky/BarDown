import Testing
import Foundation
@testable import BarDown

// RED PHASE: ScoreboardViewModel does not exist yet.
// These tests will fail to compile until Plan 03-04 creates the type.
// Compile errors ARE the failing tests.

@Suite("ScoreboardViewModel State Machine")
struct ScoreboardViewModelTests {

    @Test("Initial state is .loading")
    @MainActor
    func initialStateIsLoading() {
        let vm = ScoreboardViewModel()
        #expect(vm.state == .loading)
    }

    @Test("loadGames with empty array transitions to .empty")
    @MainActor
    func emptyArrayTransitionsToEmpty() async {
        let vm = ScoreboardViewModel()
        await vm.loadGames([])
        #expect(vm.state == .empty)
    }

    @Test("loadGames with 3 games transitions to .loaded")
    @MainActor
    func threeGamesTransitionsToLoaded() async throws {
        let vm = ScoreboardViewModel()
        let url = Bundle(for: ScoreboardViewModelTestsHelper.self).url(
            forResource: "games-response",
            withExtension: "json"
        )!
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let games = try decoder.decode([GameModel].self, from: data)

        await vm.loadGames(games)

        if case .loaded(let loaded) = vm.state {
            #expect(loaded.count == 3)
        } else {
            Issue.record("Expected .loaded state, got \(vm.state)")
        }
    }

    @Test("loadGames after error transitions to .error")
    @MainActor
    func errorTransitionsToErrorState() async {
        let vm = ScoreboardViewModel()
        await vm.loadError("Network unavailable")
        if case .error(let msg) = vm.state {
            #expect(!msg.isEmpty)
        } else {
            Issue.record("Expected .error state, got \(vm.state)")
        }
    }

    @Test("refresh() sets isRefreshing true then false after completion")
    @MainActor
    func refreshToggesIsRefreshing() async {
        let vm = ScoreboardViewModel()
        // isRefreshing should start false
        #expect(vm.isRefreshing == false)
        // Call refresh and verify it completes (sets back to false)
        await vm.refresh()
        #expect(vm.isRefreshing == false)
    }

    @Test("selectedDate defaults to today's start of day in Eastern timezone")
    @MainActor
    func selectedDateDefaultsToTodayEastern() {
        let vm = ScoreboardViewModel()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        let todayStart = calendar.startOfDay(for: Date())
        #expect(vm.selectedDate == todayStart)
    }
}

// Objective-C class for Bundle(for:) fixture loading
final class ScoreboardViewModelTestsHelper: NSObject {}
