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

    @State private var ballOffset: CGFloat = 0
    @State private var shadowScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .bottom) {
                // Shadow ellipse — shrinks when ball is up, grows when ball is down
                Ellipse()
                    .fill(Color.black.opacity(0.15))
                    .frame(width: 24 * shadowScale, height: 6 * shadowScale)
                    .offset(y: 22)

                // White lacrosse ball
                Circle()
                    .fill(Color.white)
                    .frame(width: 24, height: 24)
                    .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                    .offset(y: ballOffset)
            }
            .frame(height: 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .onChange(of: isRefreshing) { _, newValue in
            if newValue {
                startBouncing()
            } else {
                stopBouncing()
            }
        }
        .onAppear {
            if isRefreshing { startBouncing() }
        }
    }

    private func startBouncing() {
        withAnimation(
            .interpolatingSpring(stiffness: 180, damping: 8)
            .repeatForever(autoreverses: true)
        ) {
            ballOffset = -16
            shadowScale = 0.6
        }
    }

    private func stopBouncing() {
        withAnimation(.easeOut(duration: 0.2)) {
            ballOffset = 0
            shadowScale = 1.0
        }
    }
}
