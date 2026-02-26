import SwiftUI

struct LiveIndicator: View {
    var size: CGFloat = 8
    var color: Color = .red
    @State private var isBlinking = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .opacity(isBlinking ? 0.3 : 1.0)
            .animation(
                .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                value: isBlinking
            )
            .onAppear { isBlinking = true }
    }
}
