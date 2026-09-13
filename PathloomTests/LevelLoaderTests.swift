import XCTest
@testable import Pathloom

final class LevelLoaderTests: XCTestCase {
    func testLevelLoadingFromBundle() throws {
        let catalog = try LevelLoader().loadCatalog()
        XCTAssertGreaterThanOrEqual(catalog.levels.count, 100)
        XCTAssertEqual(catalog.levels.first?.id, 1)
        XCTAssertEqual(try LevelLoader().level(id: 1).gridSize, catalog.levels[0].gridSize)
    }

    func testPathCalculationMatchesDirection() {
        let right = PathCalculator.pathToEdge(from: GridPosition(row: 1, column: 0), direction: .right, gridSize: 4)
        XCTAssertEqual(right.map(\.column), [1, 2, 3])
        let up = PathCalculator.pathToEdge(from: GridPosition(row: 2, column: 1), direction: .up, gridSize: 3)
        XCTAssertEqual(up.map(\.row), [1, 0])
    }
}
