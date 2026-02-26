import SwiftUI

// PreferenceKey to track scroll offset for custom pull-to-refresh
struct ScrollOffsetKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// The lacrosse ball animation view shown during pull and refresh
struct PullToRefreshView: View {
    let isRefreshing: Bool

    @State private var bouncing = false

    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .bottom) {
                // Shadow ellipse — shrinks when ball is up, grows when ball is down
                Ellipse()
                    .fill(Color.white.opacity(0.18))
                    .frame(
                        width: bouncing ? 14 : 24,
                        height: bouncing ? 4 : 6
                    )
                    .offset(y: 22)

                // White lacrosse ball
                Circle()
                    .fill(Color.white)
                    .frame(width: 24, height: 24)
                    .shadow(color: .white.opacity(0.35), radius: 4, y: 2)
                    .offset(y: bouncing ? -18 : 0)
            }
            .frame(height: 44)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .onAppear {
            startBouncing()
        }
    }

    private func startBouncing() {
        withAnimation(
            .easeInOut(duration: 0.45)
            .repeatForever(autoreverses: true)
        ) {
            bouncing = true
        }
    }
}
