import SwiftUI

struct ScoreboardTab: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(0..<8) { index in
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.regularMaterial)
                            .frame(height: 100)
                            .overlay {
                                Text("Game \(index + 1)")
                                    .foregroundStyle(.secondary)
                            }
                    }
                }
                .padding()
            }
            .navigationTitle("Scores")
        }
    }
}

#Preview {
    ScoreboardTab()
}
