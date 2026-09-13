import SpriteKit

final class ArrowNode: SKNode {
    let arrowID: Int
    private let sprite: SKSpriteNode
    private let hitTarget: SKShapeNode
    private var cellSize: CGFloat
    private var currentDirection: Direction

    init(arrow: Arrow, size: CGFloat) {
        arrowID = arrow.id
        cellSize = size
        currentDirection = arrow.direction
        sprite = SKSpriteNode(texture: ArrowNode.texture(size: size))
        hitTarget = SKShapeNode(rectOf: CGSize(width: size, height: size), cornerRadius: size * 0.12)
        super.init()
        name = "arrow-\(arrow.id)"
        isUserInteractionEnabled = false

        hitTarget.fillColor = .clear
        hitTarget.strokeColor = .clear
        addChild(hitTarget)

        sprite.size = CGSize(width: size * 0.92, height: size * 0.92)
        sprite.zRotation = ArrowGlyph.spriteRotation(for: arrow.direction)
        addChild(sprite)
        setScale(1)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateFill(direction: Direction) {
        currentDirection = direction
        sprite.zRotation = ArrowGlyph.spriteRotation(for: direction)
    }

    func makeTrailGhost() -> SKSpriteNode {
        let ghost = SKSpriteNode(texture: sprite.texture)
        ghost.size = sprite.size
        ghost.zRotation = sprite.zRotation
        ghost.alpha = 0.32
        return ghost
    }

    func playBlocked() {
        removeAction(forKey: "blocked")
        let axis: CGVector
        switch currentDirection {
        case .left, .right: axis = CGVector(dx: 5, dy: 0)
        case .up, .down: axis = CGVector(dx: 0, dy: 5)
        }
        let sequence = SKAction.sequence([
            SKAction.moveBy(x: -axis.dx, y: -axis.dy, duration: 0.05),
            SKAction.moveBy(x: axis.dx * 2, y: axis.dy * 2, duration: 0.05),
            SKAction.moveBy(x: -axis.dx * 1.4, y: -axis.dy * 1.4, duration: 0.05),
            SKAction.moveBy(x: axis.dx * 0.4, y: axis.dy * 0.4, duration: 0.03)
        ])
        run(sequence, withKey: "blocked")
    }

    private static func texture(size: CGFloat) -> SKTexture {
        SKTexture(image: ArrowGlyph.image(size: size, color: BoardPalette.arrow, style: .straight))
    }
}
