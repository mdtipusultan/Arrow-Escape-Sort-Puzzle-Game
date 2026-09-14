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
        XCTAssertGreaterThanOrEqual(byID[25]?.arrowCount ?? 0, 10)
        XCTAssertGreaterThanOrEqual(byID[50]?.arrowCount ?? 0, 16)
        XCTAssertGreaterThanOrEqual(byID[100]?.arrowCount ?? 0, 22)
        XCTAssertGreaterThan(byID[100]?.gridSize ?? 0, byID[10]?.gridSize ?? 99)
    }
}
