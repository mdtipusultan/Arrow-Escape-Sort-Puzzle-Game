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
}
