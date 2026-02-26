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
        VStack(spacing: 5) {
            if game.isScheduled {
                Text(scheduledTimeLabel)
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .fontWeight(.semibold)
                    .foregroundStyle(.white.opacity(0.95))

                Text("SCHEDULED")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.62))
                    .tracking(1.1)
            } else {
                HStack(spacing: 2) {
                    Text("\(game.awayScore)")
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Text("-")
                        .foregroundStyle(Color.white.opacity(0.8))
                    Text("\(game.homeScore)")
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
                .font(.system(size: 50, weight: .black, design: .rounded))
                .monospacedDigit()
            }

            if game.isLive {
                LiveClockChip(period: game.period, clock: game.clock)
            } else if game.isFinal {
                Text("FINAL")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.72))
                    .tracking(1)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct LiveClockChip: View {
    let period: String?
    let clock: String?

    private var label: String {
        let periodLabel = period?.trimmingCharacters(in: .whitespacesAndNewlines)
        let clockLabel = clock?.trimmingCharacters(in: .whitespacesAndNewlines)

        if let periodLabel, !periodLabel.isEmpty, let clockLabel, !clockLabel.isEmpty {
            return "\(periodLabel) \(clockLabel)"
        }
        if let periodLabel, !periodLabel.isEmpty {
            return periodLabel
        }
        if let clockLabel, !clockLabel.isEmpty {
            return clockLabel
        }
        return "LIVE"
    }

    var body: some View {
        HStack(spacing: 6) {
            LiveIndicator(size: 7, color: .red)
            Text(label.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.88))
                .monospacedDigit()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Capsule().fill(Color.white.opacity(0.10)))
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
    }
}
