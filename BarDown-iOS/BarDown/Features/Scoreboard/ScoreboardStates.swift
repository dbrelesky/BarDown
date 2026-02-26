import SwiftUI
import Darwin

struct ScoreboardLoadingView: View {
    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<5, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                    .frame(height: 178)
                    .shimmering()
            }
        }
        .allowsHitTesting(false)
    }
}

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
            Spacer(minLength: 80)
            Image(systemName: "sportscourt")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundStyle(Color.white.opacity(0.45))

            Text("Sorry folks, no ball scheduled today.")
                .font(.headline)
                .foregroundStyle(Color.white.opacity(0.84))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer(minLength: 120)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ScoreboardErrorView: View {
    let message: String
    let retryAction: () async -> Void

    var body: some View {
        VStack(spacing: 15) {
            Spacer(minLength: 80)
            Image(systemName: "wifi.slash")
                .font(.system(size: 48))
                .foregroundStyle(Color.white.opacity(0.46))

            Text("Couldn't load scores")
                .font(.headline)
                .foregroundStyle(Color.white.opacity(0.84))

            Text(message)
                .font(.caption)
                .foregroundStyle(Color.white.opacity(0.56))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button("Try Again") {
                Task { await retryAction() }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.black.opacity(0.85))
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(Capsule().fill(Color.white.opacity(0.9)))

            Spacer(minLength: 120)
        }
        .frame(maxWidth: .infinity)
    }
}
