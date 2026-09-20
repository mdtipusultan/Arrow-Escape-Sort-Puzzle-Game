import XCTest
@testable import Pathloom

final class MapLayoutEngineTests: XCTestCase {
    func testSnakePathStaysOnScreenAndDoesNotOverlap() {
        let layout = MapLayoutEngine.layout(
            levelCount: 200,
            canvasWidth: 390,
            safeLeft: 16,
            safeRight: 16,
            isPad: false
        )
        XCTAssertEqual(layout.nodes.count, 200)
        XCTAssertGreaterThan(layout.size.height, 8_000)
        XCTAssertEqual(layout.nodes.first?.levelID, 1)
        XCTAssertEqual(layout.nodes.last?.levelID, 200)

        for node in layout.nodes {
            XCTAssertGreaterThan(node.position.x, node.radius)
            XCTAssertLessThan(node.position.x, layout.size.width - node.radius)
            XCTAssertGreaterThan(node.position.y, 40)
            XCTAssertLessThan(node.position.y, layout.size.height - 40)
        }

        let first = layout.nodes[0]
        let last = layout.nodes[199]
        XCTAssertGreaterThan(first.position.y, last.position.y)

        let xs = layout.nodes.map(\.position.x)
        XCTAssertGreaterThan((xs.max() ?? 0) - (xs.min() ?? 0), 80)

        for index in 1..<layout.nodes.count {
            let a = layout.nodes[index - 1]
            let b = layout.nodes[index]
            let dx = a.position.x - b.position.x
            let dy = a.position.y - b.position.y
            let distance = (dx * dx + dy * dy).squareRoot()
            XCTAssertGreaterThan(distance, a.radius + b.radius - 2, "Overlap at \(a.levelID)-\(b.levelID)")
        }
    }

    func testIPadPathIsWiderThanIPhonePath() {
        let phone = MapLayoutEngine.layout(levelCount: 40, canvasWidth: 390, safeLeft: 16, safeRight: 16, isPad: false)
        let pad = MapLayoutEngine.layout(levelCount: 40, canvasWidth: 1024, safeLeft: 20, safeRight: 20, isPad: true)
        let phoneSpan = (phone.nodes.map(\.position.x).max() ?? 0) - (phone.nodes.map(\.position.x).min() ?? 0)
        let padSpan = (pad.nodes.map(\.position.x).max() ?? 0) - (pad.nodes.map(\.position.x).min() ?? 0)
        XCTAssertGreaterThan(padSpan, phoneSpan)
    }

    func testChaptersCoverEveryLevel() {
        let chapters = MapLayoutEngine.chapters(for: 200)
        XCTAssertEqual(chapters.first?.range.lowerBound, 1)
        XCTAssertEqual(chapters.last?.range.upperBound, 200)
        XCTAssertEqual(chapters.count, 9)
    }
}
