import Testing
import Foundation
@testable import BarDown

// RED PHASE: DateStripViewModel does not exist yet.
// These tests will fail to compile until Plan 03-04 creates the type.
// Compile errors ARE the failing tests.

@Suite("DateStrip Date Filtering and Selection")
struct DateStripTests {

    // Helper: parse an ISO8601 date string in Eastern timezone
    private func date(from string: String) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        var components = DateComponents()
        let parts = string.split(separator: "-").map { Int($0)! }
        components.year = parts[0]
        components.month = parts[1]
        components.day = parts[2]
        components.hour = 0
        components.minute = 0
        components.second = 0
        return calendar.date(from: components)!
    }

    @Test("DateStrip only displays game dates, not every calendar day in range")
    func onlyGameDatesDisplayed() {
        let gameDates: [Date] = [
            date(from: "2026-03-01"),
            date(from: "2026-03-03"),
            date(from: "2026-03-05"),
        ]
        let vm = DateStripViewModel(gameDates: gameDates)
        // The strip must expose exactly those 3 dates, not all days in the range
        #expect(vm.displayDates.count == 3)
        #expect(vm.displayDates.contains(date(from: "2026-03-01")))
        #expect(vm.displayDates.contains(date(from: "2026-03-03")))
        #expect(vm.displayDates.contains(date(from: "2026-03-05")))
        // No in-between date like March 2 or March 4
        #expect(!vm.displayDates.contains(date(from: "2026-03-02")))
        #expect(!vm.displayDates.contains(date(from: "2026-03-04")))
    }

    @Test("Selecting a date updates selectedDate on the parent ViewModel")
    @MainActor
    func selectingDateUpdatesViewModel() {
        let gameDates: [Date] = [
            date(from: "2026-03-01"),
            date(from: "2026-03-03"),
            date(from: "2026-03-05"),
        ]
        let scoreboardVM = ScoreboardViewModel()
        let stripVM = DateStripViewModel(gameDates: gameDates, selectionSink: scoreboardVM)

        stripVM.select(date(from: "2026-03-03"))
        #expect(scoreboardVM.selectedDate == date(from: "2026-03-03"))
    }

    @Test("Date string formatter uses America/New_York timezone")
    func formatterUsesEasternTimezone() {
        let gameDates: [Date] = [
            date(from: "2026-03-01"),
        ]
        let vm = DateStripViewModel(gameDates: gameDates)
        // The label for March 1, 2026 must not show March 2 (UTC offset issue)
        let label = vm.label(for: date(from: "2026-03-01"))
        #expect(label.contains("Mar") || label.contains("1"))
        // Must not accidentally roll into March 2
        #expect(!label.contains("2"))
    }
}
