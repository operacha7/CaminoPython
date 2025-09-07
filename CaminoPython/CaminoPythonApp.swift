import SwiftUI

@main
struct CaminoPythonApp: App {
    @StateObject private var appState = AppState()
    var body: some Scene {
        WindowGroup {
            SettingsView()
                .environmentObject(appState)
        }
    }
}
