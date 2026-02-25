import SwiftUI

struct CalendarSheetView: View {
    @Binding var selectedDate: Date
    let gameDates: [Date]
    let onDateSelected: (Date) -> Void

    @State private var displayedMonth: Date = .now

    private var calendarDates: [Date] {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/New_York")!
        // All days in displayed month
        let range = cal.range(of: .day, in: .month, for: displayedMonth)!
        let firstDay = cal.date(from: cal.dateComponents([.year, .month], from: displayedMonth))!
        return range.compactMap { day in
            cal.date(byAdding: .day, value: day - 1, to: firstDay)
        }
    }

    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Month navigation
                HStack {
                    Button {
                        advanceMonth(by: -1)
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    Spacer()
                    Text(displayedMonth, format: .dateTime.month(.wide).year())
                        .font(.headline)
                    Spacer()
                    Button {
                        advanceMonth(by: 1)
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                }
                .padding(.horizontal)

                // Day-of-week headers
                HStack {
                    ForEach(["S","M","T","W","T","F","S"], id: \.self) { day in
                        Text(day)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)

                // Calendar grid
                LazyVGrid(columns: columns, spacing: 8) {
                    // Leading offset for first weekday
                    ForEach(0..<leadingOffset, id: \.self) { _ in
                        Color.clear.frame(height: 36)
                    }
                    ForEach(calendarDates, id: \.self) { date in
                        let hasGames = gameDates.contains { Calendar.current.isDate($0, inSameDayAs: date) }
                        let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                        DayCell(date: date, hasGames: hasGames, isSelected: isSelected)
                            .onTapGesture {
                                guard hasGames else { return }
                                onDateSelected(date)
                            }
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 16)
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private var leadingOffset: Int {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 1  // Sunday
        let firstDay = cal.date(from: cal.dateComponents([.year, .month], from: displayedMonth))!
        return cal.component(.weekday, from: firstDay) - 1
    }

    private func advanceMonth(by value: Int) {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/New_York")!
        displayedMonth = cal.date(byAdding: .month, value: value, to: displayedMonth) ?? displayedMonth
    }
}

private struct DayCell: View {
    let date: Date
    let hasGames: Bool
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 2) {
            Text(date, format: .dateTime.day())
                .font(.callout)
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundStyle(hasGames ? .primary : .tertiary)
                .frame(width: 32, height: 32)
                .background {
                    if isSelected {
                        Circle().fill(.tint)
                    }
                }

            // Dot indicator for dates with games
            Circle()
                .fill(hasGames ? Color.accentColor : .clear)
                .frame(width: 4, height: 4)
        }
        .opacity(hasGames ? 1.0 : 0.4)
    }
}
