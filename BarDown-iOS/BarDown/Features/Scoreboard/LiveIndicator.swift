import SwiftUI

struct LiveIndicator: View {
    @State private var isBlinking = false

    var body: some View {
        Circle()
            .fill(Color.red)
            .frame(width: 8, height: 8)
            .opacity(isBlinking ? 0.3 : 1.0)
            .animation(
                .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                value: isBlinking
            )
            .onAppear { isBlinking = true }
    }
}
