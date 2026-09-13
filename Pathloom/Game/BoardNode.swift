import SpriteKit

final class BoardNode: SKNode {
    private(set) var boardSize: CGFloat = 0
    private(set) var cellSize: CGFloat = 0
    private(set) var gap: CGFloat = 0
    private(set) var gridSize: Int = 0
    private var origin: CGPoint = .zero

    func layout(gridSize: Int, in available: CGSize) {
        removeAllChildren()
        self.gridSize = gridSize
        let side = min(available.width, available.height)
        boardSize = side
        let padding = side * AppConstants.Board.paddingFactor
        let inner = side - padding * 2
        gap = inner * AppConstants.Board.cellGapFactor / CGFloat(max(gridSize, 1))
        cellSize = (inner - gap * CGFloat(max(gridSize - 1, 0))) / CGFloat(max(gridSize, 1))
        origin = CGPoint(x: -side / 2 + padding + cellSize / 2, y: -side / 2 + padding + cellSize / 2)

        let rect = CGRect(x: -side / 2, y: -side / 2, width: side, height: side)
        let corner = side * AppConstants.Board.cornerRadiusFactor

        let bg = SKShapeNode(rect: rect, cornerRadius: corner)
        bg.fillColor = BoardPalette.board
        bg.strokeColor = .clear
        addChild(bg)

        let dotRadius = max(1.4, cellSize * 0.055)
        for row in 0..<gridSize {
            for column in 0..<gridSize {
                let dot = SKShapeNode(circleOfRadius: dotRadius)
                dot.fillColor = BoardPalette.dot
                dot.strokeColor = .clear
                dot.position = pointForCell(row: row, column: column)
                dot.zPosition = 1
                addChild(dot)
            }
        }
    }

    func pointForCell(row: Int, column: Int) -> CGPoint {
        let stride = cellSize + gap
        return CGPoint(
            x: origin.x + CGFloat(column) * stride,
            y: origin.y + CGFloat(gridSize - 1 - row) * stride
        )
    }

    func cell(at scenePoint: CGPoint) -> GridPosition? {
        guard gridSize > 0 else { return nil }
        let local = convert(scenePoint, from: parent ?? self)
        for row in 0..<gridSize {
            for column in 0..<gridSize {
                let center = pointForCell(row: row, column: column)
                let half = cellSize / 2
                let rect = CGRect(x: center.x - half, y: center.y - half, width: cellSize, height: cellSize)
                if rect.contains(local) {
                    return GridPosition(row: row, column: column)
                }
            }
        }
        return nil
    }

    func exitPoint(from position: GridPosition, direction: Direction) -> CGPoint {
        let start = pointForCell(row: position.row, column: position.column)
        let travel = boardSize * 0.72
        switch direction {
        case .up: return CGPoint(x: start.x, y: start.y + travel)
        case .down: return CGPoint(x: start.x, y: start.y - travel)
        case .left: return CGPoint(x: start.x - travel, y: start.y)
        case .right: return CGPoint(x: start.x + travel, y: start.y)
        }
    }

    func pathPoints(from position: GridPosition, direction: Direction, gridSize: Int) -> [CGPoint] {
        var points: [CGPoint] = []
        for cell in PathCalculator.pathToEdge(from: position, direction: direction, gridSize: gridSize) {
            points.append(pointForCell(row: cell.row, column: cell.column))
        }
        points.append(exitPoint(from: position, direction: direction))
        return points
    }
}
