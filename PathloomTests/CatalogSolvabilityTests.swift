import XCTest
@testable import Pathloom

final class CatalogSolvabilityTests: XCTestCase {
    func testLevelSolverFindsSolutionForEveryShippedLevel() throws {
        let catalog = try LevelLoader().loadCatalog()
        XCTAssertGreaterThanOrEqual(catalog.levels.count, 200)
        var failures: [Int] = []
        for level in catalog.levels {
            if LevelSolver.solve(level: level) == nil {
                failures.append(level.id)
            }
        }
        XCTAssertTrue(failures.isEmpty, "Unsolvable levels: \(failures)")
    }

    func testCatalogDifficultyRamps() throws {
        let catalog = try LevelLoader().loadCatalog()
        let byID = Dictionary(uniqueKeysWithValues: catalog.levels.map { ($0.id, $0) })
        XCTAssertEqual(byID[1]?.arrowCount, 1)
        XCTAssertLessThanOrEqual(byID[8]?.arrowCount ?? 99, 8)
        XCTAssertGreaterThanOrEqual(byID[25]?.arrowCount ?? 0, 10)
        XCTAssertGreaterThanOrEqual(byID[50]?.arrowCount ?? 0, 15)
        XCTAssertGreaterThanOrEqual(byID[100]?.arrowCount ?? 0, 20)
        XCTAssertGreaterThanOrEqual(byID[200]?.arrowCount ?? 0, 28)
        XCTAssertGreaterThan(byID[100]?.gridSize ?? 0, byID[10]?.gridSize ?? 99)

        let early = catalog.levels.prefix(10).compactMap(\.difficultyScore).reduce(0, +)
        let late = catalog.levels.suffix(10).compactMap(\.difficultyScore).reduce(0, +)
        XCTAssertGreaterThan(late, early * 1.4)

        let midScores = catalog.levels.filter { (30...40).contains($0.id) }.compactMap(\.difficultyScore)
        let lateScores = catalog.levels.filter { (80...100).contains($0.id) }.compactMap(\.difficultyScore)
        let midAvg = midScores.reduce(0, +) / Double(max(midScores.count, 1))
        let lateAvg = lateScores.reduce(0, +) / Double(max(lateScores.count, 1))
        XCTAssertGreaterThan(lateAvg, midAvg * 0.95)
    }

    func testEveryLevelHasSolverParAndValidGeometry() throws {
        let catalog = try LevelLoader().loadCatalog()
        for level in catalog.levels {
            XCTAssertFalse(LevelGraph.hasOverlaps(level), "Overlap on \(level.id)")
            XCTAssertFalse(LevelGraph.hasOutOfBounds(level), "OOB on \(level.id)")
            let report = LevelSolver.report(level: level)
            XCTAssertNotNil(report, "No report for \(level.id)")
            XCTAssertEqual(report?.optimalMoves, level.arrowCount)
            XCTAssertEqual(level.parMoves, report?.optimalMoves)
        }
    }

    func testConsecutiveLevelsUseDifferentArchetypes() throws {
        let catalog = try LevelLoader().loadCatalog()
        let archetypes = catalog.levels.map(\.resolvedPatternType)
        for index in 1..<archetypes.count {
            XCTAssertNotEqual(archetypes[index], archetypes[index - 1], "Repeated archetype at \(index + 1)")
        }
    }
}
