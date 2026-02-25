import SwiftUI

@main
struct BarDownApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark) // DESG-03: Dark is hero aesthetic
        }
    }
}
