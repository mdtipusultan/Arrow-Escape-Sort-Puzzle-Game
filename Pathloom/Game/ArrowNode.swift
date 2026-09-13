import SpriteKit

final class ArrowNode: SKNode {
    let arrowID: Int
    private let shape: SKShapeNode
    private let shadow: SKShapeNode

    init(arrow: Arrow, size: CGFloat) {
        arrowID = arrow.id
        let path = ArrowNode.chevronPath(in: size)
        shadow = SKShapeNode(path: path)
        shape = SKShapeNode(path: path)
        super.init()
        name = "arrow-\(arrow.id)"
        isUserInteractionEnabled = false

        shadow.fillColor = SKColor.black.withAlphaComponent(0.12)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -size * 0.04)
        addChild(shadow)

        shape.fillColor = BoardPalette.fill(for: arrow.direction)
        shape.strokeColor = SKColor.white.withAlphaComponent(0.35)
        shape.lineWidth = max(1, size * 0.035)
        addChild(shape)

        zRotation = arrow.direction.rotationRadians
        setScale(1)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateFill(direction: Direction) {
        shape.fillColor = BoardPalette.fill(for: direction)
        zRotation = direction.rotationRadians
    }

    func playBlocked() {
        removeAction(forKey: "blocked")
        let dx = 5.0
        let sequence = SKAction.sequence([
            SKAction.moveBy(x: -dx, y: 0, duration: 0.05),
            SKAction.moveBy(x: dx * 2, y: 0, duration: 0.05),
            SKAction.moveBy(x: -dx * 1.4, y: 0, duration: 0.05),
            SKAction.moveBy(x: dx * 0.4, y: 0, duration: 0.03),
            SKAction.scale(to: 1.04, duration: 0.04),
            SKAction.scale(to: 1.0, duration: 0.08)
        ])
        run(sequence, withKey: "blocked")
    }

    static func chevronPath(in size: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let w = size * 0.62
        let h = size * 0.68
        path.move(to: CGPoint(x: 0, y: h * 0.48))
        path.addLine(to: CGPoint(x: w * 0.42, y: -h * 0.18))
        path.addLine(to: CGPoint(x: w * 0.16, y: -h * 0.18))
        path.addLine(to: CGPoint(x: w * 0.16, y: -h * 0.48))
        path.addLine(to: CGPoint(x: -w * 0.16, y: -h * 0.48))
        path.addLine(to: CGPoint(x: -w * 0.16, y: -h * 0.18))
        path.addLine(to: CGPoint(x: -w * 0.42, y: -h * 0.18))
        path.closeSubpath()
        return path
    }
}
