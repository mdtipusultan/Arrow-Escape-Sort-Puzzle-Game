import Foundation
import Observation

@MainActor
@Observable
final class GameViewModel {
    private(set) var engine: GameEngine
    private(set) var state: GameState
    private(set) var tutorialMessage: String?
    private(set) var boardEpoch: Int = 0
    private(set) var showTutorialPulse: Bool
    var debugOverlay = false
    var showSolutionIDs: [Int] = []

    var level: Level { engine.level }
    var remainingCount: Int { engine.remainingCount }
    var moveCount: Int { engine.moveCount }
    var canUndo: Bool { engine.canUndo }

    private let services: AppServices
    private var pendingAnimations = 0

    weak var scene: GameScene?

    init(level: Level, services: AppServices) {
        self.services = services
        engine = GameEngine(level: level)
        state = .ready
        showTutorialPulse = level.id == 1
        tutorialMessage = level.id == 1 ? "Tap the open path." : nil
        state = .playing
    }

    func attach(_ scene: GameScene) {
        self.scene = scene
        scene.setDebugOverlay(debugOverlay)
        scene.load(engine: engine)
        if showTutorialPulse, let first = engine.remainingArrows.first {
            scene.showTutorialPulse(on: first.id)
        }
    }

    func handleTap(arrowID: Int) {
        guard state == .playing, pendingAnimations == 0 else { return }
        guard engine.arrow(id: arrowID)?.isActive == true else { return }

        services.audio.play(.arrowTap)
        services.haptics.lightTap()

        switch engine.attemptEscape(arrowID) {
        case .blocked:
            services.audio.play(.arrowBlocked)
            services.haptics.blocked()
            scene?.playBlocked(arrowID: arrowID)
        case .escaped:
            pendingAnimations += 1
            scene?.setInteractionLocked(true)
            services.audio.play(.arrowMove)
            if level.id == 1 {
                showTutorialPulse = false
                tutorialMessage = engine.isCleared ? nil : "Great. Find the next clear path."
            }
            scene?.animateEscape(arrowID: arrowID) { [weak self] in
                Task { @MainActor in
                    self?.finishEscape()
                }
            }
        }
    }

    func pause() {
        guard state == .playing else { return }
        state = .paused
    }

    func resume() {
        guard state == .paused else { return }
        state = .playing
    }

    func restart() {
        engine.reset()
        state = .playing
        pendingAnimations = 0
        boardEpoch += 1
        showTutorialPulse = level.id == 1
        tutorialMessage = level.id == 1 ? "Tap the open path." : nil
        scene?.setInteractionLocked(false)
        scene?.load(engine: engine)
        if showTutorialPulse, let first = engine.remainingArrows.first {
            scene?.showTutorialPulse(on: first.id)
        }
    }

    func undo() {
        guard state == .playing, engine.undo() else { return }
        boardEpoch += 1
        scene?.load(engine: engine)
        services.haptics.selection()
    }

    func showHint() {
        guard state == .playing, let id = engine.hintArrowID() else { return }
        scene?.showHint(arrowID: id)
        services.haptics.selection()
    }

    func revealSolution() {
        showSolutionIDs = LevelSolver.solve(level: level) ?? []
    }

    private func finishEscape() {
        pendingAnimations = max(0, pendingAnimations - 1)
        if engine.isCleared {
            state = .completing
            scene?.setInteractionLocked(false)
            scene?.celebrateClear()
            services.audio.play(.levelComplete)
            services.haptics.success()
            services.progress.recordCompletion(
                levelID: level.id,
                moves: moveCount,
                totalLevels: AppConstants.totalLevels,
                stars: engine.starRating
            )
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(AppConstants.Animation.completeHold))
                self.state = .completed
            }
        } else {
            scene?.setInteractionLocked(false)
            state = .playing
        }
    }
}
