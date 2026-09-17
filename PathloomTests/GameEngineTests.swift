import Foundation
import XCTest
@testable import Pathloom

final class GameEngineTests: XCTestCase {
    func testArrowCanEscapeWhenPathIsClear() {
        let level = Level(
            id: 1,
            gridSize: 3,
            parMoves: 1,
            difficulty: .tutorial,
            arrows: [ArrowData(id: 1, row: 1, column: 0, direction: .right)],
            seed: 1
        )
        var engine = GameEngine(level: level)
        XCTAssertTrue(engine.canEscape(1))
        XCTAssertEqual(engine.attemptEscape(1), .escaped(pathLength: 3))
        XCTAssertTrue(engine.isCleared)
    }

    func testArrowIsBlockedByAnotherArrow() {
        let level = Level(
            id: 2,
            gridSize: 3,
            parMoves: 2,
            difficulty: .easy,
            arrows: [
                ArrowData(id: 1, row: 1, column: 0, direction: .right),
                ArrowData(id: 2, row: 1, column: 2, direction: .up)
            ],
            seed: 2
        )
        var engine = GameEngine(level: level)
        XCTAssertFalse(engine.canEscape(1))
        XCTAssertEqual(engine.blockingArrowID(for: 1), 2)
        XCTAssertEqual(engine.attemptEscape(1), .blocked)
        XCTAssertTrue(engine.canEscape(2))
        XCTAssertEqual(engine.attemptEscape(2), .escaped(pathLength: 2))
        XCTAssertTrue(engine.canEscape(1))
    }

    func testArrowMovesCorrectly() {
        let level = Level(
            id: 3,
            gridSize: 4,
            parMoves: 1,
            difficulty: .easy,
            arrows: [ArrowData(id: 7, row: 0, column: 3, direction: .left)],
            seed: 3
        )
        var engine = GameEngine(level: level)
        let cells = engine.pathCells(for: 7)
        XCTAssertEqual(cells, [
            GridPosition(row: 0, column: 2),
            GridPosition(row: 0, column: 1),
            GridPosition(row: 0, column: 0)
        ])
        XCTAssertEqual(engine.attemptEscape(7), .escaped(pathLength: 4))
        XCTAssertEqual(engine.moveCount, 1)
        XCTAssertEqual(engine.remainingCount, 0)
    }

    @MainActor
    func testCompletedLevelUnlocksNextLevel() {
        let defaults = UserDefaults(suiteName: "pathloom.tests.progress")!
        defaults.removePersistentDomain(forName: "pathloom.tests.progress")
        let manager = ProgressManager(defaults: defaults)
        XCTAssertEqual(manager.progress.highestUnlockedLevel, 1)
        manager.recordCompletion(levelID: 1, moves: 4, totalLevels: 100)
        XCTAssertTrue(manager.progress.isCompleted(1))
        XCTAssertEqual(manager.progress.highestUnlockedLevel, 2)
        manager.recordCompletion(levelID: 1, moves: 2, totalLevels: 100)
        XCTAssertEqual(manager.progress.best(for: 1), 2)
    }

    func testWinDetectionRequiresEveryArrowRemoved() {
        let level = Level(
            id: 4,
            gridSize: 3,
            parMoves: 2,
            difficulty: .easy,
            arrows: [
                ArrowData(id: 1, row: 0, column: 0, direction: .down),
                ArrowData(id: 2, row: 0, column: 2, direction: .left)
            ],
            seed: 4
        )
        var engine = GameEngine(level: level)
        _ = engine.attemptEscape(1)
        XCTAssertFalse(engine.isCleared)
        _ = engine.attemptEscape(2)
        XCTAssertTrue(engine.isCleared)
    }

    func testUndoRestoresBlockedState() {
        let level = Level(
            id: 5,
            gridSize: 3,
            parMoves: 1,
            difficulty: .easy,
            arrows: [ArrowData(id: 1, row: 2, column: 1, direction: .up)],
            seed: 5
        )
        var engine = GameEngine(level: level)
        _ = engine.attemptEscape(1)
        XCTAssertTrue(engine.undo())
        XCTAssertEqual(engine.remainingCount, 1)
        XCTAssertEqual(engine.moveCount, 0)
    }
}
