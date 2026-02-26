import SwiftUI

struct GameCardView: View {
    let game: GameModel
    @Environment(\.openURL) private var openURL

    private var awayIsWinner: Bool {
        game.isFinal && game.awayScore > game.homeScore
    }

    private var homeIsWinner: Bool {
        game.isFinal && game.homeScore > game.awayScore
    }

    private var borderColor: Color {
        if game.isLive { return Color.yellow.opacity(0.72) }
        if game.isFinal { return Color.white.opacity(0.15) }
        return Color.white.opacity(0.10)
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.19, green: 0.21, blue: 0.28),
                Color(red: 0.12, green: 0.14, blue: 0.20),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center, spacing: 8) {
                TeamColumnView(
                    team: game.awayTeam,
                    score: game.awayScore,
                    isWinner: awayIsWinner,
                    isLive: game.isLive,
                    showScore: false
                )

                ScoreCenterView(game: game)
                    .frame(maxWidth: 150)

                TeamColumnView(
                    team: game.homeTeam,
                    score: game.homeScore,
                    isWinner: homeIsWinner,
                    isLive: game.isLive,
                    showScore: false
                )
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 14)

            if !game.isScheduled, let urlString = game.boxScoreURL, let url = URL(string: urlString) {
                Button {
                    openURL(url)
                } label: {
                    HStack(spacing: 4) {
                        Text("Box Score")
                            .font(.caption2.weight(.semibold))
                        Image(systemName: "arrow.up.right")
                            .font(.caption2.weight(.semibold))
                    }
                    .foregroundStyle(.white.opacity(0.78))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 14)
            }
        }
        .padding(.top, 18)
        .padding(.bottom, 12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(backgroundGradient)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(borderColor, lineWidth: game.isLive ? 1.5 : 1)
        }
        .overlay(alignment: .top) {
            GameStatusChip(game: game)
                .offset(y: -11)
        }
        .overlay(alignment: .topTrailing) {
            if game.isLive {
                Image(systemName: "star.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.yellow.opacity(0.92))
                    .padding(.top, 8)
                    .padding(.trailing, 10)
            }
        }
        .shadow(color: game.isLive ? Color.yellow.opacity(0.18) : Color.black.opacity(0.30), radius: 10, y: 5)
    }
}

private struct GameStatusChip: View {
    let game: GameModel

    private var easternCalendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/New_York")!
        return cal
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        formatter.timeZone = TimeZone(identifier: "America/New_York")!
        return formatter
    }()

    private var chipLabel: String {
        switch game.gameStatus {
        case .live:
            return "LIVE"
        case .final_:
            return "FINAL"
        case .scheduled:
            if easternCalendar.isDateInToday(game.startTime) {
                return "TODAY, \(dateFormatter.string(from: game.startTime).uppercased())"
            }
            return dateFormatter.string(from: game.startTime).uppercased()
        }
    }

    private var chipFill: Color {
        switch game.gameStatus {
        case .live:
            return Color.yellow.opacity(0.86)
        case .final_:
            return Color.white.opacity(0.16)
        case .scheduled:
            return Color.green.opacity(0.76)
        }
    }

    var body: some View {
        Text(chipLabel)
            .font(.caption2.weight(.bold))
            .foregroundStyle(game.isLive ? Color.black.opacity(0.86) : Color.white.opacity(0.9))
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Capsule().fill(chipFill))
    }
}

#Preview {
    VStack(spacing: 12) {
        GameCardView(game: .placeholder)
    }
    .padding()
    .background(Color.black)
}
