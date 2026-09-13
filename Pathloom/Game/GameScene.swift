import SpriteKit
import UIKit

protocol GameSceneDelegate: AnyObject {
    func gameSceneDidTapArrow(id: Int)
}

final class GameScene: SKScene {
    weak var gameDelegate: GameSceneDelegate?

    private let board = BoardNode()
    private var arrowNodes: [Int: ArrowNode] = [:]
    private var engine: GameEngine?
    private var debugOverlayEnabled = false
    private var debugLabels: [SKLabelNode] = []
    private var interactionLocked = false
    private var tutorialPulse: SKNode?

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        if board.parent == nil {
            addChild(board)
        }
        rebuild()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        rebuild()
    }

    func load(engine: GameEngine) {
        self.engine = engine
        rebuild()
    }

    func setInteractionLocked(_ locked: Bool) {
        interactionLocked = locked
    }

    func showHint(arrowID: Int) {
        guard let node = arrowNodes[arrowID] else { return }
        node.removeAction(forKey: "hint")
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.12, duration: 0.18),
            SKAction.scale(to: 1.0, duration: 0.18)
        ])
        node.run(SKAction.repeat(pulse, count: 3), withKey: "hint")
    }

    func showTutorialPulse(on arrowID: Int) {
        if tutorialPulse != nil { return }
        tutorialPulse?.removeFromParent()
        guard let node = arrowNodes[arrowID] else { return }
        let ring = SKShapeNode(circleOfRadius: max(board.cellSize * 0.48, 12))
        ring.strokeColor = BoardPalette.arrow
        ring.lineWidth = 3
        ring.fillColor = .clear
        ring.alpha = 0.9
        ring.position = node.position
        ring.zPosition = 20
        addChild(ring)
        tutorialPulse = ring
        let pulse = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.25, duration: 0.7),
                SKAction.fadeAlpha(to: 0.15, duration: 0.7)
            ]),
            SKAction.group([
                SKAction.scale(to: 1.0, duration: 0.01),
                SKAction.fadeAlpha(to: 0.9, duration: 0.01)
            ])
        ])
        ring.run(SKAction.repeatForever(pulse))
    }

    func clearTutorialPulse() {
        tutorialPulse?.removeFromParent()
        tutorialPulse = nil
    }

    func playBlocked(arrowID: Int) {
        arrowNodes[arrowID]?.playBlocked()
    }

    func animateEscape(arrowID: Int, completion: @escaping () -> Void) {
        guard let engine, let arrow = engine.arrow(id: arrowID), let node = arrowNodes[arrowID] else {
            completion()
            return
        }
        clearTutorialPulse()
        var waypoints = board.pathPoints(
            from: arrow.position,
            direction: arrow.direction,
            gridSize: engine.level.gridSize
        )
        if waypoints.isEmpty {
            waypoints = [board.exitPoint(from: arrow.position, direction: arrow.direction)]
        }
        let distance = PathCalculator.stepsToEdge(
            from: arrow.position,
            direction: arrow.direction,
            gridSize: engine.level.gridSize
        )
        let duration = interpolatedDuration(steps: distance)
        spawnArrowTrail(from: node, along: waypoints, duration: duration)

        var moves: [SKAction] = []
        let stepDuration = duration / Double(max(waypoints.count, 1))
        for (index, point) in waypoints.enumerated() {
            let move = SKAction.move(to: point, duration: stepDuration)
            move.timingMode = index == waypoints.count - 1 ? .easeIn : .linear
            moves.append(move)
        }
        let fade = SKAction.fadeOut(withDuration: AppConstants.Animation.fadeExit)
        node.run(SKAction.sequence(moves + [fade, SKAction.removeFromParent()])) { [weak self] in
            self?.arrowNodes[arrowID] = nil
            completion()
        }
    }

    func celebrateClear() {
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 64
        emitter.numParticlesToEmit = 40
        emitter.particleLifetime = 0.7
        emitter.particleSpeed = 80
        emitter.particleSpeedRange = 40
        emitter.emissionAngleRange = .pi * 2
        emitter.particleAlpha = 0.8
        emitter.particleAlphaSpeed = -1.1
        emitter.particleScale = 0.12
        emitter.particleScaleSpeed = -0.1
        emitter.particleColor = BoardPalette.arrow
        emitter.particleColorBlendFactor = 1
        emitter.particleTexture = SKTexture(image: sparkImage())
        emitter.zPosition = 50
        addChild(emitter)
       emitter.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.8),
            SKAction.removeFromParent()
        ]))
    }

    func setDebugOverlay(_ enabled: Bool) {
        debugOverlayEnabled = enabled
        for label in debugLabels {
            label.isHidden = !enabled
        }
        if enabled && debugLabels.isEmpty {
            rebuild()
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !interactionLocked, let touch = touches.first else { return }
        let location = touch.location(in: self)
        for node in nodes(at: location) {
            if let arrow = Self.arrow(from: node) {
                gameDelegate?.gameSceneDidTapArrow(id: arrow.arrowID)
                return
            }
        }
        if let cell = board.cell(at: location),
           let match = engine?.remainingArrows.first(where: { $0.position == cell }) {
            gameDelegate?.gameSceneDidTapArrow(id: match.id)
        }
    }

    private static func arrow(from node: SKNode) -> ArrowNode? {
        var current: SKNode? = node
        while let inspected = current {
            if let arrow = inspected as? ArrowNode {
                return arrow
            }
            current = inspected.parent
        }
        return nil
    }

    private func rebuild() {
        guard let engine else { return }
        let inset = min(size.width, size.height) * 0.02
        let available = CGSize(width: max(size.width - inset * 2, 10), height: max(size.height - inset * 2, 10))
        board.layout(gridSize: engine.level.gridSize, in: available)
        board.position = .zero

        for node in arrowNodes.values {
            node.removeFromParent()
        }
        arrowNodes.removeAll()
        debugLabels.forEach { $0.removeFromParent() }
        debugLabels.removeAll()
        tutorialPulse?.removeFromParent()
        tutorialPulse = nil

        for arrow in engine.remainingArrows {
            let node = ArrowNode(arrow: arrow, size: board.cellSize * 0.9)
            node.position = board.pointForCell(row: arrow.position.row, column: arrow.position.column)
            node.zPosition = 10
            addChild(node)
            arrowNodes[arrow.id] = node

            if debugOverlayEnabled {
                let label = SKLabelNode(fontNamed: "Menlo")
                label.text = "\(arrow.id) \(arrow.position.row),\(arrow.position.column)"
                label.fontSize = max(8, board.cellSize * 0.16)
                label.fontColor = .black
                label.verticalAlignmentMode = .center
                label.horizontalAlignmentMode = .center
                label.position = CGPoint(x: node.position.x, y: node.position.y - board.cellSize * 0.38)
                label.zPosition = 30
                addChild(label)
                debugLabels.append(label)
            }
        }
    }

    private func interpolatedDuration(steps: Int) -> TimeInterval {
        let t = min(max(Double(steps) / 8.0, 0), 1)
        return AppConstants.Animation.moveMin + (AppConstants.Animation.moveMax - AppConstants.Animation.moveMin) * t
    }

    private func spawnArrowTrail(from node: ArrowNode, along waypoints: [CGPoint], duration: TimeInterval) {
        guard !waypoints.isEmpty else { return }
        for index in 1...3 {
            let ghost = node.makeTrailGhost()
            ghost.position = node.position
            ghost.zPosition = 8
            ghost.alpha = 0.34 - CGFloat(index) * 0.08
            addChild(ghost)
            var moves: [SKAction] = [SKAction.wait(forDuration: 0.045 * Double(index))]
            let stepDuration = duration / Double(max(waypoints.count, 1))
            for point in waypoints {
                moves.append(SKAction.move(to: point, duration: stepDuration))
            }
            ghost.run(SKAction.sequence(moves + [
                SKAction.fadeOut(withDuration: 0.12),
                SKAction.removeFromParent()
            ]))
        }
    }

    private func sparkImage() -> UIImage {
        let size = CGSize(width: 8, height: 8)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.white.setFill()
            context.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))
        }
    }
}
