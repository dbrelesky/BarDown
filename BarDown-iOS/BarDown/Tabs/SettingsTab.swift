import SwiftUI

struct SettingsTab: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Preferences") {
                    Label("Notifications", systemImage: "bell.fill")
                    Label("Appearance", systemImage: "paintbrush.fill")
                }

                Section("Data") {
                    Label("Refresh Interval", systemImage: "arrow.clockwise")
                    Label("Cache", systemImage: "internaldrive.fill")
                }

                Section("About") {
                    Label("Version", systemImage: "info.circle.fill")
                    Label("Acknowledgements", systemImage: "heart.fill")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsTab()
}
