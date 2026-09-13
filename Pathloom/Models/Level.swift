import Foundation

enum Difficulty: String, Codable, Sendable {
    case tutorial
    case easy
    case medium
    case hard
    case expert
}

struct Level: Identifiable, Codable, Hashable, Sendable {
    let id: Int
    let gridSize: Int
    let parMoves: Int
    let difficulty: Difficulty
    let arrows: [ArrowData]
    let seed: Int?

    var arrowCount: Int { arrows.count }
}

struct LevelCatalog: Codable, Sendable {
    let levels: [Level]
}
