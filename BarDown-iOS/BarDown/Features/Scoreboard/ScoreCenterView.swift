import SwiftUI

struct ScoreCenterView: View {
    let game: GameModel

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        f.timeZone = TimeZone(identifier: "America/New_York")!
        return f
    }()

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
                // Show start time + venue placeholder
                Text(timeFormatter.string(from: game.startTime))
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }
}
