import SwiftUI

@main
struct PathloomApp: App {
    @State private var services = AppServices()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(services)
                .preferredColorScheme(services.settings.appearance.colorScheme)
                .onAppear {
                    services.syncToggles()
                    services.audio.startMusicIfNeeded()
                }
                .onChange(of: services.settings.soundEnabled) { _, _ in
                    services.syncToggles()
                }
                .onChange(of: services.settings.musicEnabled) { _, _ in
                    services.syncToggles()
                }
                .onChange(of: services.settings.hapticsEnabled) { _, _ in
                    services.syncToggles()
                }
        }
    }
}
