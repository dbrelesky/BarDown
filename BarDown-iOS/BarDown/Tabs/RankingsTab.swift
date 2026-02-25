import SwiftUI

struct RankingsTab: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(0..<8) { index in
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.regularMaterial)
                            .frame(height: 100)
                            .overlay {
                                Text("Ranking \(index + 1)")
                                    .foregroundStyle(.secondary)
                            }
                    }
                }
                .padding()
            }
            .navigationTitle("Rankings")
        }
    }
}

#Preview {
    RankingsTab()
}
