import AVFoundation
import Foundation

protocol AudioPlaying: AnyObject {
    func play(_ effect: SoundEffect)
    func setSoundEnabled(_ enabled: Bool)
    func setMusicEnabled(_ enabled: Bool)
    func startMusicIfNeeded()
    func stopMusic()
}

enum SoundEffect: String, CaseIterable {
    case arrowTap
    case arrowMove
    case arrowBlocked
    case levelComplete
    case buttonTap
    case levelUnlock
    case onboardingNext
}

@MainActor
final class AudioManager: AudioPlaying {
    private var effectPlayers: [SoundEffect: AVAudioPlayer] = [:]
    private var musicPlayer: AVAudioPlayer?
    private var soundEnabled = true
    private var musicEnabled = true
    private var didConfigureSession = false

    init() {
        configureSession()
        preload()
    }

    func play(_ effect: SoundEffect) {
        guard soundEnabled else { return }
        guard let player = effectPlayers[effect] else { return }
        player.currentTime = 0
        player.volume = AppConstants.Audio.effectsVolume
        player.play()
    }

    func setSoundEnabled(_ enabled: Bool) {
        soundEnabled = enabled
    }

    func setMusicEnabled(_ enabled: Bool) {
        musicEnabled = enabled
        if enabled {
            startMusicIfNeeded()
        } else {
            stopMusic()
        }
    }

    func startMusicIfNeeded() {
        guard musicEnabled else { return }
        configureSession()
        if musicPlayer == nil {
            musicPlayer = makePlayer(named: "musicLoop")
            musicPlayer?.numberOfLoops = -1
            musicPlayer?.volume = AppConstants.Audio.musicVolume
        }
        if musicPlayer?.isPlaying != true {
            musicPlayer?.play()
        }
    }

    func stopMusic() {
        musicPlayer?.stop()
    }

    private func configureSession() {
        guard !didConfigureSession else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            didConfigureSession = true
        } catch {
            didConfigureSession = false
        }
    }

    private func preload() {
        for effect in SoundEffect.allCases {
            effectPlayers[effect] = makePlayer(named: effect.rawValue)
        }
        musicPlayer = makePlayer(named: "musicLoop")
        musicPlayer?.numberOfLoops = -1
        musicPlayer?.volume = AppConstants.Audio.musicVolume
    }

    private func makePlayer(named resource: String) -> AVAudioPlayer? {
        let url = Bundle.main.url(forResource: resource, withExtension: "wav")
            ?? Bundle.main.url(forResource: resource, withExtension: "caf")
        guard let url else { return nil }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            return player
        } catch {
            return nil
        }
    }
}
