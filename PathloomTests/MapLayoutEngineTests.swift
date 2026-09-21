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
        XCTAssertEqual(chapters.count, 8)
        XCTAssertEqual(chapters.first?.title, "Sunthread Meadows")
        XCTAssertEqual(chapters.last?.title, "Aurora Spire")
    }

    func testMilestonesMatchZoneBoundaries() {
        XCTAssertTrue(MapLayoutEngine.isMilestone(25))
        XCTAssertTrue(MapLayoutEngine.isMilestone(100))
        XCTAssertTrue(MapLayoutEngine.isMilestone(200))
        XCTAssertFalse(MapLayoutEngine.isMilestone(1))
        XCTAssertFalse(MapLayoutEngine.isMilestone(10))
    }

    func testCompactPhoneKeepsNodesInsideSafeBand() {
        let layout = MapLayoutEngine.layout(
            levelCount: 200,
            canvasWidth: 320,
            safeLeft: 0,
            safeRight: 0,
            isPad: false
        )
        for node in layout.nodes {
            XCTAssertGreaterThan(node.position.x, node.radius)
            XCTAssertLessThan(node.position.x, layout.size.width - node.radius)
        }
    }

    func testWindingPathDoesNotTeleportBetweenNeighbors() {
        let layout = MapLayoutEngine.layout(
            levelCount: 80,
            canvasWidth: 390,
            safeLeft: 16,
            safeRight: 16,
            isPad: false
        )
        for index in 1..<layout.nodes.count {
            let dx = abs(layout.nodes[index].position.x - layout.nodes[index - 1].position.x)
            XCTAssertLessThan(dx, 90, "Jump at \(index)-\(index + 1)")
        }
    }
}

final class MapProgressManagerTests: XCTestCase {
    func testNewPlayerFocusesLevelOne() {
        let progress = PlayerProgress.fresh
        XCTAssertNil(MapProgressManager.lastCompletedLevel(progress: progress))
        XCTAssertEqual(MapProgressManager.currentLevel(progress: progress, totalLevels: 200), 1)
        XCTAssertEqual(MapProgressManager.nextPlayableLevel(progress: progress, totalLevels: 200), 1)
        XCTAssertEqual(MapProgressManager.focusLevelID(progress: progress, totalLevels: 200, pendingReveal: nil), 1)
    }

    func testCompletedLevelFocusesNextPlayable() {
        var progress = PlayerProgress.fresh
        progress.completedLevels = Set(1...37)
        progress.highestUnlockedLevel = 38
        XCTAssertEqual(MapProgressManager.lastCompletedLevel(progress: progress), 37)
        XCTAssertEqual(MapProgressManager.currentLevel(progress: progress, totalLevels: 200), 38)
        XCTAssertEqual(MapProgressManager.nextPlayableLevel(progress: progress, totalLevels: 200), 38)
        XCTAssertEqual(MapProgressManager.focusLevelID(progress: progress, totalLevels: 200, pendingReveal: nil), 38)
        XCTAssertEqual(MapProgressManager.state(for: 37, progress: progress, currentID: 38), .completed)
        XCTAssertEqual(MapProgressManager.state(for: 38, progress: progress, currentID: 38), .current)
        XCTAssertEqual(MapProgressManager.state(for: 39, progress: progress, currentID: 38), .locked)
    }

    func testPendingRevealWinsOverCurrentProgress() {
        var progress = PlayerProgress.fresh
        progress.completedLevels = Set(1...37)
        progress.highestUnlockedLevel = 38
        XCTAssertEqual(
            MapProgressManager.focusLevelID(progress: progress, totalLevels: 200, pendingReveal: 38),
            38
        )
    }

    func testAllClearedFocusesFinalLevel() {
        var progress = PlayerProgress.fresh
        progress.completedLevels = Set(1...200)
        progress.highestUnlockedLevel = 200
        XCTAssertEqual(MapProgressManager.currentLevel(progress: progress, totalLevels: 200), 200)
        XCTAssertEqual(MapProgressManager.focusLevelID(progress: progress, totalLevels: 200, pendingReveal: nil), 200)
    }
}
