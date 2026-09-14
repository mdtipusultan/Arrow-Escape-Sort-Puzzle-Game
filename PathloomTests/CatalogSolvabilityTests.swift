import XCTest
@testable import Pathloom

final class CatalogSolvabilityTests: XCTestCase {
    func testLevelSolverFindsSolutionForEveryShippedLevel() throws {
        let catalog = try LevelLoader().loadCatalog()
        XCTAssertGreaterThanOrEqual(catalog.levels.count, 100)
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
        XCTAssertGreaterThanOrEqual(byID[25]?.arrowCount ?? 0, 7)
        XCTAssertGreaterThanOrEqual(byID[50]?.arrowCount ?? 0, 14)
        XCTAssertGreaterThanOrEqual(byID[100]?.arrowCount ?? 0, 22)
        XCTAssertGreaterThan(byID[100]?.gridSize ?? 0, byID[10]?.gridSize ?? 99)

        let early = catalog.levels.prefix(10).compactMap(\.difficultyScore).reduce(0, +)
        let late = catalog.levels.suffix(10).compactMap(\.difficultyScore).reduce(0, +)
        XCTAssertGreaterThan(late, early)
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
        let archetypes = catalog.levels.map { $0.archetype ?? "" }
        for index in 1..<archetypes.count {
            XCTAssertNotEqual(archetypes[index], archetypes[index - 1], "Repeated archetype at \(index + 1)")
        }
    }
}
