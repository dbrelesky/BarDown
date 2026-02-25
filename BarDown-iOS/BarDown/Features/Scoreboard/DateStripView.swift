import SwiftUI

struct DateStripView: View {
    @Bindable var viewModel: ScoreboardViewModel

    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE\nMMMd"  // "Wed\nMar5"
        f.timeZone = TimeZone(identifier: "America/New_York")!
        return f
    }()

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 4) {
                    ForEach(viewModel.gameDates, id: \.self) { date in
                        DateCell(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: viewModel.selectedDate),
                            formatter: formatter
                        )
                        .id(date)
                        .onTapGesture {
                            withAnimation(.spring(duration: 0.25)) {
                                viewModel.selectedDate = date
                                proxy.scrollTo(date, anchor: .center)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .onAppear {
                // Scroll to today on appear
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
        .frame(height: 60)
    }
}

private struct DateCell: View {
    let date: Date
    let isSelected: Bool
    let formatter: DateFormatter

    var body: some View {
        Text(formatter.string(from: date))
            .font(.caption2)
            .fontWeight(isSelected ? .semibold : .regular)
            .multilineTextAlignment(.center)
            .foregroundStyle(isSelected ? .primary : .secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background {
                if isSelected {
                    Capsule()
                        .fill(.tint.opacity(0.15))
                        .overlay(Capsule().stroke(.tint, lineWidth: 1))
                }
            }
            .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}
