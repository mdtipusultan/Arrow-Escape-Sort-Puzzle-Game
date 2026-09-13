import SwiftUI

struct SettingsView: View {
    @Environment(AppServices.self) private var services
    @State private var confirmReset = false

    var body: some View {
        @Bindable var settings = services.settings
        Form {
            Section("Audio") {
                Toggle("Sound Effects", isOn: $settings.soundEnabled)
                Toggle("Music", isOn: $settings.musicEnabled)
            }
            Section("Feel") {
                Toggle("Haptics", isOn: $settings.hapticsEnabled)
                Picker("Appearance", selection: $settings.appearance) {
                    ForEach(ColorSchemePreference.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
            }
            Section("About") {
                NavigationLink("About") { LegalPageView(title: "About", bodyText: LegalCopy.about) }
                NavigationLink("Privacy Policy") { LegalPageView(title: "Privacy Policy", bodyText: LegalCopy.privacy) }
                NavigationLink("Terms") { LegalPageView(title: "Terms", bodyText: LegalCopy.terms) }
            }
            Section {
                Button("Reset Progress", role: .destructive) {
                    confirmReset = true
                }
            }
        }
        .navigationTitle("Settings")
        .confirmationDialog("Reset all progress?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset Progress", role: .destructive) {
                services.progress.reset()
                services.audio.play(.buttonTap)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Completed levels, unlocks, and best scores will be cleared on this device.")
        }
    }
}

struct LegalPageView: View {
    let title: String
    let bodyText: String

    var body: some View {
        ScrollView {
            Text(bodyText)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(PathloomPalette.text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .background(PathloomPalette.background.ignoresSafeArea())
        .navigationTitle(title)
    }
}

enum LegalCopy {
    static let about = """
    Pathloom is an original casual puzzle about clearing geometric arrows from a board. Plan the order, keep paths open, and weave your way through one hundred handmade-style layouts.

    Version 1.0
    """

    static let privacy = """
    Pathloom stores your progress, audio preferences, and onboarding state on this device. The game does not require an account and does not send personal information to a server.
    """

    static let terms = """
    Pathloom is provided for personal entertainment. All puzzles, audio, and artwork in this app are original to Pathloom. Play fairly, keep backups of nothing—progress lives locally—and have fun finding the open path.
    """
}
