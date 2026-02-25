import SwiftUI
import Darwin

// MARK: - Loading (skeleton cards)

struct ScoreboardLoadingView: View {
    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<5, id: \.self) { _ in
                GameCardView(game: .placeholder)
                    .redacted(reason: .placeholder)
                    .shimmering()
            }
        }
        .padding(.horizontal)
        .allowsHitTesting(false)
    }
}

// Shimmering modifier — subtle animated opacity pulse for skeleton loading
extension View {
    func shimmering() -> some View {
        self.modifier(ShimmerModifier())
    }
}

private struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .opacity(0.6 + 0.4 * Darwin.sin(Double(phase)))
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    phase = .pi
                }
            }
    }
}

// MARK: - Empty State

struct ScoreboardEmptyView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            // Empty goal illustration — use SF Symbol as stand-in for now
            // (Phase 4+ will add a custom illustration asset)
            Image(systemName: "sportscourt")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundStyle(.tertiary)

            Text("Sorry folks, no ball scheduled today.")
                .font(.headline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }
}

// MARK: - Error State

struct ScoreboardErrorView: View {
    let message: String
    let retryAction: () async -> Void

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "wifi.slash")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            Text("Couldn't load scores")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(message)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button("Try Again") {
                Task { await retryAction() }
            }
            .buttonStyle(.bordered)
            Spacer()
        }
    }
}
