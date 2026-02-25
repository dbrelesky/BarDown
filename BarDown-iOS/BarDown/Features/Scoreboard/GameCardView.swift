import SwiftUI

struct GameCardView: View {
    let game: GameModel
    // NOTE: No onTapGesture — view-only in Phase 3 (tap opens game detail in Phase 5)

    private var awayIsWinner: Bool {
        game.isFinal && game.awayScore > game.homeScore
    }

    private var homeIsWinner: Bool {
        game.isFinal && game.homeScore > game.awayScore
    }

    var body: some View {
        VStack(spacing: 0) {
            // Away team row
            TeamRowView(
                team: game.awayTeam,
                score: game.awayScore,
                isWinner: awayIsWinner,
                isLive: game.isLive
            )

            // Center score / time / status block
            Divider()
                .padding(.leading, 80)  // align with team name, not logo
            ScoreCenterView(game: game)
            Divider()
                .padding(.leading, 80)

            // Home team row
            TeamRowView(
                team: game.homeTeam,
                score: game.homeScore,
                isWinner: homeIsWinner,
                isLive: game.isLive
            )
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: game.isLive ? .red.opacity(0.12) : .black.opacity(0.06),
                        radius: game.isLive ? 8 : 4,
                        y: 2)
        )
        // Live game: subtle red accent border
        .overlay {
            if game.isLive {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
            }
        }
        // DESG-02: game cards must use opaque backgrounds — no glass modifiers
    }
}

#Preview {
    VStack(spacing: 12) {
        GameCardView(game: .placeholder)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
