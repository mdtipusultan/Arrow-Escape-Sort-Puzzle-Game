import Foundation
import Observation

@MainActor
@Observable
final class AppServices {
    let settings: SettingsStore
    let progress: ProgressManager
    let audio: AudioPlaying
    let haptics: HapticPlaying
    let levels: LevelLoading

    private(set) var catalog: LevelCatalog
    private(set) var loadError: LevelLoaderError?
    var pendingMapFocus: Int?

    init(
        settings: SettingsStore = SettingsStore(),
        progress: ProgressManager = ProgressManager(),
        audio: AudioPlaying = AudioManager(),
        haptics: HapticPlaying = HapticManager(),
        levels: LevelLoading = LevelLoader()
    ) {
        self.settings = settings
        self.progress = progress
        self.audio = audio
        self.haptics = haptics
        self.levels = levels

        do {
            catalog = try levels.loadCatalog()
            loadError = nil
        } catch let error as LevelLoaderError {
            catalog = LevelCatalog(levels: [LevelLoader.fallbackTutorialLevel()])
            loadError = error
        } catch {
            catalog = LevelCatalog(levels: [LevelLoader.fallbackTutorialLevel()])
            loadError = .decodingFailed
        }

        audio.setSoundEnabled(settings.soundEnabled)
        audio.setMusicEnabled(settings.musicEnabled)
        haptics.isEnabled = settings.hapticsEnabled
    }

    func level(id: Int) -> Level {
        catalog.levels.first(where: { $0.id == id }) ?? LevelLoader.fallbackTutorialLevel()
    }

    func continueLevelID() -> Int {
        min(progress.progress.highestUnlockedLevel, catalog.levels.map(\.id).max() ?? 1)
    }

    func syncToggles() {
        audio.setSoundEnabled(settings.soundEnabled)
        audio.setMusicEnabled(settings.musicEnabled)
        haptics.isEnabled = settings.hapticsEnabled
    }
}
