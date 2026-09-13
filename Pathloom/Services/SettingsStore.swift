import Foundation
import Observation
import SwiftUI

enum ColorSchemePreference: String, CaseIterable, Identifiable, Sendable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

@MainActor
@Observable
final class SettingsStore {
    private let defaults: UserDefaults

    var soundEnabled: Bool {
        didSet { defaults.set(soundEnabled, forKey: Keys.sound) }
    }

    var musicEnabled: Bool {
        didSet {
            defaults.set(musicEnabled, forKey: Keys.music)
            NotificationCenter.default.post(name: .pathloomMusicPreferenceChanged, object: nil)
        }
    }

    var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: Keys.haptics) }
    }

    var appearance: ColorSchemePreference {
        didSet { defaults.set(appearance.rawValue, forKey: Keys.appearance) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        soundEnabled = defaults.object(forKey: Keys.sound) as? Bool ?? true
        musicEnabled = defaults.object(forKey: Keys.music) as? Bool ?? true
        hapticsEnabled = defaults.object(forKey: Keys.haptics) as? Bool ?? true
        if let raw = defaults.string(forKey: Keys.appearance),
           let value = ColorSchemePreference(rawValue: raw) {
            appearance = value
        } else {
            appearance = .system
        }
    }

    private enum Keys {
        static let sound = "pathloom.soundEnabled"
        static let music = "pathloom.musicEnabled"
        static let haptics = "pathloom.hapticsEnabled"
        static let appearance = "pathloom.appearance"
    }
}

extension Notification.Name {
    static let pathloomMusicPreferenceChanged = Notification.Name("pathloom.musicPreferenceChanged")
}
