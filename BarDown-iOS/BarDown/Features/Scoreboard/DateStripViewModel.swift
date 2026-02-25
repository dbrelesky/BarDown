import Foundation

/// A lightweight view model for the horizontal date strip.
/// Holds only the game dates and delegates selection back to the parent ScoreboardViewModel.
///
/// Not @MainActor so tests can call `init`, `displayDates`, and `label(for:)` from
/// nonisolated contexts. Only `select()` is @MainActor because it mutates the
/// @MainActor-isolated ScoreboardViewModel.
final class DateStripViewModel {

    // MARK: - State

    /// Only dates that have games — the strip never shows in-between empty days.
    let displayDates: [Date]

    // MARK: - Private

    private let selectionSink: ScoreboardViewModel?

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
    /// Must be called from @MainActor context because ScoreboardViewModel is @MainActor.
    @MainActor
    func select(_ date: Date) {
        selectionSink?.selectedDate = date
    }

    /// Returns the formatted label for a given game date (Eastern timezone).
    func label(for date: Date) -> String {
        formatter.string(from: date)
    }
}
