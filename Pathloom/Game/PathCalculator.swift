import Foundation

struct PathCalculator: Sendable {
    static func pathToEdge(from position: GridPosition, direction: Direction, gridSize: Int) -> [GridPosition] {
        var cells: [GridPosition] = []
        var cursor = position.stepped(in: direction)
        while cursor.isInside(gridSize: gridSize) {
            cells.append(cursor)
            cursor = cursor.stepped(in: direction)
        }
        return cells
    }

    static func stepsToEdge(from position: GridPosition, direction: Direction, gridSize: Int) -> Int {
        switch direction {
        case .up: position.row + 1
        case .down: gridSize - position.row
        case .left: position.column + 1
        case .right: gridSize - position.column
        }
    }
}
