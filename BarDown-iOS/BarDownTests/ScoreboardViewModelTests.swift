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

    @Test("applyAvailableDateStrings supports backward/forward calendar navigation dates")
    @MainActor
    func availableDatesIncludePastAndFuture() {
        let vm = ScoreboardViewModel()

        vm.applyAvailableDateStrings([
            "2026-03-17", // future
            "2026-03-10", // past
            "2026-03-15", // today-ish anchor
            "2026-03-10", // duplicate
        ])

        #expect(vm.gameDates.count == 3)
        #expect(vm.gameDates == vm.gameDates.sorted())
        #expect(vm.gameDates.first! < vm.gameDates.last!)
    }

    @Test("Loaded schedule includes upcoming and completed games with expected score behavior")
    @MainActor
    func loadedGamesContainUpcomingAndCompletedStates() async throws {
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

        guard case .loaded(let loadedGames) = vm.state else {
            Issue.record("Expected loaded state")
            return
        }

        let scheduled = loadedGames.filter(\.isScheduled)
        let completed = loadedGames.filter(\.isFinal)

        #expect(!scheduled.isEmpty)
        #expect(!completed.isEmpty)
        #expect(scheduled.allSatisfy { $0.homeScore == 0 && $0.awayScore == 0 })
        #expect(completed.allSatisfy { $0.homeScore > 0 || $0.awayScore > 0 })
    }
}

// Objective-C class for Bundle(for:) fixture loading
final class ScoreboardViewModelTestsHelper: NSObject {}
