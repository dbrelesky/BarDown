import Foundation
import Observation

@Observable
@MainActor
final class ScoreboardViewModel {

    enum State: Equatable {
        case loading
        case loaded([GameModel])
        case empty
        case error(String)

        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.loading, .loading): return true
            case (.empty, .empty): return true
            case (.loaded(let a), .loaded(let b)): return a.map(\.id) == b.map(\.id)
            case (.error(let a), .error(let b)): return a == b
            default: return false
            }
        }
    }

    // MARK: - Observed State

    var state: State = .loading
    var selectedDate: Date
    var gameDates: [Date] = []   // only dates with games, for the date strip
    var isRefreshing: Bool = false

    // MARK: - Private

    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
        self.selectedDate = ScoreboardViewModel.easternStartOfToday()
    }

    // MARK: - Public Methods (network-facing)

    func loadGames(for date: Date) async {
        state = .loading
        do {
            let games = try await apiClient.fetchGames(for: date)
            loadGames(games)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func refresh() async {
        isRefreshing = true
        await loadGames(for: selectedDate)
        isRefreshing = false
    }

    func loadAvailableDates() async {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/New_York")!
        let today = Self.easternStartOfToday()
        let from = cal.date(byAdding: .day, value: -30, to: today)!
        let to   = cal.date(byAdding: .day, value:  30, to: today)!

        do {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.timeZone = TimeZone(identifier: "America/New_York")!

            let dateStrings = try await apiClient.fetchAvailableDates(from: from, to: to)
            gameDates = dateStrings.compactMap { formatter.date(from: $0) }
        } catch {
            // Non-fatal: date strip will show empty, user can still navigate
            gameDates = []
        }
    }

    // MARK: - Testable overloads (take pre-fetched data; no network call)

    /// Directly set games — used in tests and by loadGames(for:) after a successful fetch.
    func loadGames(_ games: [GameModel]) {
        state = games.isEmpty ? .empty : .loaded(games.sortedByStatus())
    }

    /// Directly set an error message — used in tests.
    func loadError(_ message: String) {
        state = .error(message)
    }

    // MARK: - Private Helpers

    static func easternStartOfToday() -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/New_York")!
        return cal.startOfDay(for: .now)
    }
}

// MARK: - GameModel sort extension

extension [GameModel] {
    func sortedByStatus() -> [GameModel] {
        sorted {
            if $0.gameStatus != $1.gameStatus {
                return $0.gameStatus < $1.gameStatus
            }
            return $0.startTime < $1.startTime
        }
    }
}
