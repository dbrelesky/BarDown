import SwiftUI
import Kingfisher

struct TeamRowView: View {
    let team: TeamModel
    let score: Int
    let isWinner: Bool   // for final games — bold treatment
    let isLive: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Logo (~52pt as per CONTEXT.md 48-56pt range)
            TeamLogoView(logoAssetName: team.logoAssetName)

            // Abbreviation + record
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(team.abbreviation)
                        .font(.headline)
                        .fontWeight(isWinner ? .bold : .regular)
                        .foregroundStyle(isWinner ? .primary : .secondary)

                    // Ranking badge (e.g., "#3")
                    if let ranking = team.ranking {
                        Text("#\(ranking)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.accentColor))
                    }
                }

                if let record = team.record {
                    Text(record)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            // Score (only for live/final — upcoming handled by ScoreCenterView)
            Text("\(score)")
                .font(.title2)
                .fontWeight(isWinner ? .bold : .regular)
                .monospacedDigit()
                .foregroundStyle(isWinner ? .primary : .secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Logo View

struct TeamLogoView: View {
    let logoAssetName: String?

    var body: some View {
        Group {
            if let name = logoAssetName, let url = URL(string: name) {
                // URL-based logo — use Kingfisher for caching
                KFImage(url)
                    .resizable()
                    .placeholder {
                        Image(systemName: "sportscourt")
                            .resizable()
                            .foregroundStyle(.tertiary)
                    }
                    .scaledToFit()
            } else if let name = logoAssetName, !name.isEmpty {
                // Local asset name
                Image(name)
                    .resizable()
                    .scaledToFit()
            } else {
                // No logo available
                Image(systemName: "sportscourt")
                    .resizable()
                    .foregroundStyle(.tertiary)
                    .scaledToFit()
            }
        }
        .frame(width: 52, height: 52)
    }
}
