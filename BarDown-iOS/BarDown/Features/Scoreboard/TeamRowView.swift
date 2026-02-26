import SwiftUI
import Kingfisher

struct TeamColumnView: View {
    let team: TeamModel
    let score: Int
    let isWinner: Bool
    let isLive: Bool
    let showScore: Bool

    var body: some View {
        VStack(spacing: 6) {
            TeamLogoView(
                logoAssetName: team.normalizedLogoAssetName,
                fallbackText: team.logoFallbackText,
                size: 50
            )

            VStack(spacing: 2) {
                Text(displayName(team.name).uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.white.opacity(isWinner ? 0.98 : 0.84))
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text(team.abbreviation)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(Color.white.opacity(0.68))
                    .lineLimit(1)
            }

            if showScore {
                Text("\(score)")
                    .font(.title3.weight(isWinner ? .bold : .regular))
                    .monospacedDigit()
                    .foregroundStyle(Color.white.opacity(isWinner ? 0.96 : 0.74))
            }

            HStack(spacing: 5) {
                if let ranking = team.ranking {
                    Text("#\(ranking)")
                        .font(.caption2.weight(.bold))
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.black.opacity(0.85))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.yellow.opacity(0.9)))
                }

                if let record = team.record {
                    Text(record)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Color.white.opacity(0.58))
                }
            }
            .frame(minHeight: 15)
        }
        .frame(maxWidth: .infinity)
    }

    private func displayName(_ fullName: String) -> String {
        let tokens = fullName.split(separator: " ").map(String.init)
        guard !tokens.isEmpty else { return fullName }

        let keepTwoWordPrefixes: Set<String> = ["north", "south", "east", "west", "new", "saint", "st.", "st", "notre"]
        if tokens.count >= 2 && keepTwoWordPrefixes.contains(tokens[0].lowercased()) {
            return "\(tokens[0]) \(tokens[1])"
        }

        return tokens[0]
    }
}

struct TeamLogoView: View {
    let logoAssetName: String?
    let fallbackText: String
    var size: CGFloat = 52

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.24)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.24)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )

            Group {
                if let name = logoAssetName, let url = URL(string: name) {
                    KFImage(url)
                        .resizable()
                        .placeholder {
                            fallbackMonogram
                        }
                        .scaledToFit()
                        .padding(6)
                } else if let name = logoAssetName, !name.isEmpty {
                    Image(name)
                        .resizable()
                        .scaledToFit()
                        .padding(6)
                } else {
                    fallbackMonogram
                        .padding(6)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: size * 0.24))
        .frame(width: size, height: size)
        .shadow(color: Color.black.opacity(0.28), radius: 6, y: 3)
    }

    private var fallbackMonogram: some View {
        Text(String(fallbackText.prefix(2)))
            .font(.system(size: size * 0.34, weight: .black, design: .rounded))
            .foregroundStyle(.white.opacity(0.86))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                LinearGradient(
                    colors: [Color.white.opacity(0.14), Color.white.opacity(0.04)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

}
