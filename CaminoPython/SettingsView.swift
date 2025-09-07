import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        StandardPage(
            pageName: "Settings",
            onHome: { /* TODO: navigate to Home */ },
            onMenu: { /* TODO: open Menu */ },
            onSettings: { /* already on Settings */ }
        ) {
            // Intentionally empty: no content yet.
            EmptyView()
        }
    }
}

#Preview {
    // Preview with a sample AppState so the header shows a title
    SettingsView()
        .environmentObject(AppState())
}
