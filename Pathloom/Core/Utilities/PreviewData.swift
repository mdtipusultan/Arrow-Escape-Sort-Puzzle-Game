import Foundation

enum PreviewData {
    static let sampleLevel = Level(
        id: 1,
        gridSize: 3,
        parMoves: 1,
        difficulty: .tutorial,
        arrows: [ArrowData(id: 1, row: 1, column: 0, direction: .right)],
        seed: 1
    )
}
