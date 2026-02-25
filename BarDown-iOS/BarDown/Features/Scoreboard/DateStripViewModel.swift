import Foundation

/// A lightweight view model for the horizontal date strip.
/// Holds only the game dates and delegates selection back to the parent ScoreboardViewModel.
@Observable
@MainActor
final class DateStripViewModel {

    // MARK: - Observed State

    /// Only dates that have games — the strip never shows in-between empty days.
    var displayDates: [Date]

    // MARK: - Private

    private weak var selectionSink: ScoreboardViewModel?

    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE\nMMM d"  // e.g. "Wed\nMar 1"
        f.timeZone = TimeZone(identifier: "America/New_York")!
        return f
    }()

    // MARK: - Init

    init(gameDates: [Date], selectionSink: ScoreboardViewModel? = nil) {
        self.displayDates = gameDates
        self.selectionSink = selectionSink
    }

    // MARK: - Public Methods

    /// Select a date: updates the parent ScoreboardViewModel's selectedDate.
    func select(_ date: Date) {
        selectionSink?.selectedDate = date
    }

    /// Returns the formatted label for a given game date (Eastern timezone).
    func label(for date: Date) -> String {
        formatter.string(from: date)
    }
}
