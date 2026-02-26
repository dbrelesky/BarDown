import SwiftUI

struct ScoreboardTab: View {
    var body: some View {
        NavigationStack {
            ScoreboardView()
                .toolbar(.hidden, for: .navigationBar)
        }
    }
}

#Preview {
    ScoreboardTab()
}
