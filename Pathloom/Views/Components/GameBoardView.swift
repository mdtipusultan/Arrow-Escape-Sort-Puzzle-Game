import SpriteKit
import SwiftUI

struct GameBoardView: UIViewRepresentable {
    var viewModel: GameViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.allowsTransparency = true
        view.backgroundColor = .clear
        view.ignoresSiblingOrder = true
        view.preferredFramesPerSecond = 60
        view.isMultipleTouchEnabled = false

        let scene = GameScene(size: CGSize(width: 300, height: 300))
        scene.scaleMode = .resizeFill
        scene.gameDelegate = context.coordinator
        view.presentScene(scene)
        context.coordinator.scene = scene
        context.coordinator.viewModel = viewModel
        viewModel.scene = scene
        scene.load(engine: viewModel.engine)
        context.coordinator.boardEpoch = viewModel.boardEpoch
        context.coordinator.levelID = viewModel.level.id
        applyTutorial(scene: scene)
        return view
    }

    func updateUIView(_ view: SKView, context: Context) {
        context.coordinator.viewModel = viewModel
        guard let scene = context.coordinator.scene else { return }
        scene.gameDelegate = context.coordinator
        viewModel.scene = scene
        scene.setDebugOverlay(viewModel.debugOverlay)

        let needsReload = context.coordinator.boardEpoch != viewModel.boardEpoch
            || context.coordinator.levelID != viewModel.level.id
        if needsReload {
            scene.setInteractionLocked(false)
            scene.load(engine: viewModel.engine)
            context.coordinator.boardEpoch = viewModel.boardEpoch
            context.coordinator.levelID = viewModel.level.id
        }
        applyTutorial(scene: scene)
    }

    private func applyTutorial(scene: GameScene) {
        if viewModel.showTutorialPulse, let first = viewModel.engine.remainingArrows.first {
            scene.showTutorialPulse(on: first.id)
        } else {
            scene.clearTutorialPulse()
        }
    }

    final class Coordinator: NSObject, GameSceneDelegate {
        var viewModel: GameViewModel?
        weak var scene: GameScene?
        var boardEpoch: Int = -1
        var levelID: Int = -1

        func gameSceneDidTapArrow(id: Int) {
            let target = viewModel
            Task { @MainActor in
                target?.handleTap(arrowID: id)
            }
        }
    }
}
