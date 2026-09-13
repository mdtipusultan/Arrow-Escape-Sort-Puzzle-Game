import XCTest
@testable import Pathloom

final class LevelSolverTests: XCTestCase {
    func testLevelSolverFindsSolution() {
        let level = Level(
            id: 10,
            gridSize: 3,
            parMoves: 3,
            difficulty: .easy,
            arrows: [
                ArrowData(id: 1, row: 1, column: 0, direction: .right),
                ArrowData(id: 2, row: 1, column: 2, direction: .up),
                ArrowData(id: 3, row: 0, column: 2, direction: .left)
            ],
            seed: 10
        )
        let solution = LevelSolver.solve(level: level)
        XCTAssertEqual(solution, [3, 2, 1])
        XCTAssertTrue(LevelSolver.isSolvable(level))
    }

    func testImpossibleBoardIsRejected() {
        let level = Level(
            id: 99,
            gridSize: 2,
            parMoves: 2,
            difficulty: .easy,
            arrows: [
                ArrowData(id: 1, row: 0, column: 0, direction: .right),
                ArrowData(id: 2, row: 0, column: 1, direction: .left)
            ],
            seed: 99
        )
        XCTAssertNil(LevelSolver.solve(level: level))
        XCTAssertFalse(LevelSolver.isSolvable(level))
    }
}
