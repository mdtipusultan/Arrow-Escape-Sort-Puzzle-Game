import XCTest
@testable import Pathloom

final class LevelGeneratorTests: XCTestCase {
    func testStarRatingRewardsCleanPlay() {
        XCTAssertEqual(StarRating.stars(parMoves: 12, wastedTaps: 0, undoCount: 0), 3)
        XCTAssertEqual(StarRating.stars(parMoves: 12, wastedTaps: 1, undoCount: 0), 3)
        XCTAssertEqual(StarRating.stars(parMoves: 12, wastedTaps: 3, undoCount: 0), 2)
        XCTAssertEqual(StarRating.stars(parMoves: 12, wastedTaps: 20, undoCount: 8), 1)
    }

    func testGeneratorProducesSolvableNonTrivialLevel() {
        let spec = LevelSpec(
            id: 18,
            difficulty: .easy,
            archetype: .bottleneck,
            gridSize: 6,
            arrowCount: 10,
            targetDepth: 3...8,
            targetInitial: 1...4,
            minScore: 1.5,
            seed: 18_018
        )
        let level = LevelGenerator.generate(spec: spec)
        XCTAssertNotNil(level)
        XCTAssertTrue(LevelSolver.isSolvable(level!))
        XCTAssertGreaterThanOrEqual(level!.arrowCount, 8)
        XCTAssertGreaterThan(LevelGraph.dependencyCount(LevelGraph.blockingAdjacency(level!)), 0)
    }

    func testHandcraftedOpeningLevelsAreSolvable() {
        for id in 1...10 {
            let spec = LevelProgression.spec(for: id)
            let level = LevelGenerator.generate(spec: spec)
            XCTAssertNotNil(level)
            XCTAssertTrue(LevelSolver.isSolvable(level!), "Level \(id)")
        }
    }
}
