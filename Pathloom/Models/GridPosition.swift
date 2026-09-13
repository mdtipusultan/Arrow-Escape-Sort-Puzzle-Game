import Foundation

struct GridPosition: Hashable, Codable, Sendable {
    var row: Int
    var column: Int

    func stepped(in direction: Direction) -> GridPosition {
        GridPosition(row: row + direction.rowDelta, column: column + direction.columnDelta)
    }

    func isInside(gridSize: Int) -> Bool {
        row >= 0 && column >= 0 && row < gridSize && column < gridSize
    }
}
