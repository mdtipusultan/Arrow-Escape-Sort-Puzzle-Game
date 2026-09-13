import Foundation

struct ArrowData: Identifiable, Codable, Hashable, Sendable {
    let id: Int
    let row: Int
    let column: Int
    let direction: Direction

    var position: GridPosition {
        GridPosition(row: row, column: column)
    }
}

struct Arrow: Identifiable, Hashable, Sendable {
    let id: Int
    var position: GridPosition
    var direction: Direction
    var isActive: Bool

    init(from data: ArrowData) {
        id = data.id
        position = data.position
        direction = data.direction
        isActive = true
    }

    init(id: Int, position: GridPosition, direction: Direction, isActive: Bool = true) {
        self.id = id
        self.position = position
        self.direction = direction
        self.isActive = isActive
    }
}
