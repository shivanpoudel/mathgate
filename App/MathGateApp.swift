import SwiftUI

@main
struct MathGateApp: App {
    @StateObject private var preferences = AppPreferences()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(preferences)
                .preferredColorScheme(preferences.settings.appearance.colorScheme)
        }
    }
}
