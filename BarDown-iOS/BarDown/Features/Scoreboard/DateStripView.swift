import SwiftUI

struct DateStripView: View {
    @Bindable var viewModel: ScoreboardViewModel

    private let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        f.timeZone = TimeZone(identifier: "America/New_York")!
        return f
    }()

    private let dayNumberFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d"
        f.timeZone = TimeZone(identifier: "America/New_York")!
        return f
    }()

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 10) {
                    ForEach(viewModel.gameDates, id: \.self) { date in
                        DateCell(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: viewModel.selectedDate),
                            dayFormatter: dayFormatter,
                            dayNumberFormatter: dayNumberFormatter
                        )
                        .id(date)
                        .contentShape(RoundedRectangle(cornerRadius: 14))
                        .onTapGesture {
                            withAnimation(.spring(duration: 0.25)) {
                                viewModel.selectedDate = date
                                proxy.scrollTo(date, anchor: .center)
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
            .onAppear {
                if let today = viewModel.gameDates.first(where: {
                    Calendar.current.isDate($0, inSameDayAs: .now)
                }) {
                    proxy.scrollTo(today, anchor: .center)
                } else if let selected = viewModel.gameDates.first(where: {
                    Calendar.current.isDate($0, inSameDayAs: viewModel.selectedDate)
                }) {
                    proxy.scrollTo(selected, anchor: .center)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 66)
    }
}

private struct DateCell: View {
    let date: Date
    let isSelected: Bool
    let dayFormatter: DateFormatter
    let dayNumberFormatter: DateFormatter

    var body: some View {
        VStack(spacing: 2) {
            Text(dayFormatter.string(from: date).uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(isSelected ? Color.white.opacity(0.92) : Color.white.opacity(0.38))
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Text(dayNumberFormatter.string(from: date))
                .font(.system(size: 32, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(isSelected ? .white : Color.white.opacity(0.78))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(width: 50, height: 58)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isSelected ? Color.white.opacity(0.18) : .clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isSelected ? Color.white.opacity(0.35) : .clear, lineWidth: 1)
        )
        .shadow(
            color: isSelected ? Color.black.opacity(0.36) : .clear,
            radius: isSelected ? 8 : 0,
            y: 4
        )
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        .overlay(alignment: .bottom) {
            if Calendar.current.isDateInToday(date) && !isSelected {
                Capsule()
                    .fill(Color.green.opacity(0.9))
                    .frame(width: 5, height: 5)
                    .offset(y: -4)
            }
        }
    }
}
