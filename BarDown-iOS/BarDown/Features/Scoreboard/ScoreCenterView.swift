import SwiftUI

struct ScoreCenterView: View {
    let game: GameModel

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        f.timeZone = TimeZone(identifier: "America/New_York")!
        return f
    }()

    /// Returns "TBD" when NCAA hasn't announced the game time (midnight ET placeholder).
    private var scheduledTimeLabel: String {
        let cal = Calendar.current
        var et = cal
        et.timeZone = TimeZone(identifier: "America/New_York")!
        let hour = et.component(.hour, from: game.startTime)
        let minute = et.component(.minute, from: game.startTime)
        if hour == 0 && minute == 0 {
            return "TBD"
        }
        return timeFormatter.string(from: game.startTime)
    }

    var body: some View {
        VStack(spacing: 2) {
            switch game.gameStatus {
            case .live:
                // Score display for live game
                HStack(spacing: 4) {
                    LiveIndicator()
                    Text("LIVE")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.red)
                }
                if let period = game.period, let clock = game.clock {
                    Text("\(period)  \(clock)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

            case .final_:
                Text("FINAL")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

            case .scheduled:
                Text(scheduledTimeLabel)
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }
}
