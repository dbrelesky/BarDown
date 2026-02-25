import SwiftUI

struct ScoreboardTab: View {
    var body: some View {
        NavigationStack {
            ScoreboardView()
                .navigationTitle("Scores")
                .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    ScoreboardTab()
}
