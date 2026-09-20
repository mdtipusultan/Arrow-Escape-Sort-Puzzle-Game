import CoreGraphics
import Foundation

struct MapNodeLayout: Identifiable, Equatable, Sendable {
    var id: Int { levelID }
    let levelID: Int
    let position: CGPoint
    let radius: CGFloat
    let isMilestone: Bool
    let sectionIndex: Int
}

struct MapSectionLayout: Identifiable, Equatable, Sendable {
    var id: Int { index }
    let index: Int
    let title: String
    let subtitle: String
    let levelRange: ClosedRange<Int>
    let yTop: CGFloat
    let yBottom: CGFloat
}

struct MapLayout: Equatable, Sendable {
    let nodes: [MapNodeLayout]
    let sections: [MapSectionLayout]
    let size: CGSize
    let startPoint: CGPoint
    let endPoint: CGPoint

    func node(for levelID: Int) -> MapNodeLayout? {
        guard levelID >= 1, levelID <= nodes.count else { return nil }
        return nodes[levelID - 1]
    }

    var pathPoints: [CGPoint] {
        [startPoint] + nodes.map(\.position) + [endPoint]
    }
}

struct MapLayoutMetrics: Equatable, Sendable {
    var width: CGFloat
    var safeLeft: CGFloat
    var safeRight: CGFloat
    var isPad: Bool
    var levelCount: Int

    var nodeRadius: CGFloat { isPad ? 28 : 24 }
    var milestoneRadius: CGFloat { isPad ? 34 : 30 }
    var verticalSpacing: CGFloat { isPad ? 116 : 98 }
    var sectionGap: CGFloat { isPad ? 64 : 48 }
    var topReserved: CGFloat { 168 }
    var bottomReserved: CGFloat { 196 }

    var leadingInset: CGFloat {
        max(isPad ? 72 : 40, safeLeft + 12) + milestoneRadius
    }

    var trailingInset: CGFloat {
        max(isPad ? 72 : 40, safeRight + 12) + milestoneRadius
    }
}

enum MapLayoutEngine {
    static let patternSeed: UInt64 = 42_017
    static let milestoneIDs: Set<Int> = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 150, 200]

    static func layout(
        levelCount: Int,
        canvasWidth: CGFloat,
        safeLeft: CGFloat,
        safeRight: CGFloat,
        isPad: Bool
    ) -> MapLayout {
        let count = max(levelCount, 1)
        let metrics = MapLayoutMetrics(
            width: max(canvasWidth, 320),
            safeLeft: safeLeft,
            safeRight: safeRight,
            isPad: isPad,
            levelCount: count
        )

        let chapters = chapters(for: count)
        var yFromTop: [Int: CGFloat] = [:]
        var cursor = metrics.topReserved

        for (chapterIndex, chapter) in chapters.reversed().enumerated() {
            if chapterIndex > 0 {
                cursor += metrics.sectionGap
            }
            let ids = Array(chapter.range).reversed()
            for (offset, id) in ids.enumerated() {
                if offset > 0 {
                    cursor += metrics.verticalSpacing
                    if milestoneIDs.contains(id) {
                        cursor += metrics.verticalSpacing * 0.18
                    }
                }
                yFromTop[id] = cursor
            }
            cursor += 8
        }

        let contentBottom = cursor + metrics.bottomReserved
        let usable = max(metrics.width - metrics.leadingInset - metrics.trailingInset, 80)

        var nodes: [MapNodeLayout] = []
        nodes.reserveCapacity(count)
        for id in 1...count {
            let normalized = windingX(for: id, total: count, isPad: isPad)
            let x = metrics.leadingInset + (normalized * usable)
            let radius = milestoneIDs.contains(id) ? metrics.milestoneRadius : metrics.nodeRadius
            let sectionIndex = chapterIndex(for: id, chapters: chapters)
            nodes.append(
                MapNodeLayout(
                    levelID: id,
                    position: CGPoint(x: x, y: yFromTop[id] ?? cursor),
                    radius: radius,
                    isMilestone: milestoneIDs.contains(id),
                    sectionIndex: sectionIndex
                )
            )
        }

        var sections: [MapSectionLayout] = []
        for (index, chapter) in chapters.enumerated() {
            let ys = chapter.range.compactMap { yFromTop[$0] }
            guard let yTop = ys.min(), let yBottom = ys.max() else { continue }
            sections.append(
                MapSectionLayout(
                    index: index,
                    title: chapter.title,
                    subtitle: chapter.subtitle,
                    levelRange: chapter.range,
                    yTop: yTop - 52,
                    yBottom: yBottom + 36
                )
            )
        }

        let first = nodes.first?.position ?? CGPoint(x: metrics.width / 2, y: contentBottom - 80)
        let last = nodes.last?.position ?? CGPoint(x: metrics.width / 2, y: metrics.topReserved)
        let startPoint = CGPoint(x: metrics.width / 2, y: min(contentBottom - 48, first.y + 78))
        let endPoint = CGPoint(x: last.x, y: max(48, last.y - 72))

        return MapLayout(
            nodes: nodes,
            sections: sections,
            size: CGSize(width: metrics.width, height: contentBottom),
            startPoint: startPoint,
            endPoint: endPoint
        )
    }

    static func isMilestone(_ id: Int) -> Bool {
        milestoneIDs.contains(id)
    }

    /// 0 = far left, 1 = far right. Alternates lanes with controlled, non-periodic variation.
    static func windingX(for levelID: Int, total: Int, isPad: Bool) -> CGFloat {
        let t = Double(levelID)
        let progress = Double(levelID) / Double(max(total, 1))
        let lane = sin(t * 0.33 + 0.18)
        let wander = sin(t * 0.19 + 1.37) * 0.46
        let ripple = sin(t * 0.71 + 2.63) * 0.14
        let slow = sin(t * 0.07 + Double(levelID % 5) * 0.51) * 0.22
        let hashed = hashJitter(levelID)
        let milestoneSettle = milestoneIDs.contains(levelID) ? hashed * 0.12 : hashed * 0.28
        let padStretch = isPad ? 1.0 : 0.92
        let journey = 0.92 + (progress * 0.10)
        let mixed = (lane * 0.52 + wander + ripple + slow + milestoneSettle) * padStretch * journey
        let normalized = (mixed + 1.15) / 2.3
        return CGFloat(min(max(normalized, 0.04), 0.96))
    }

    static func chapters(for levelCount: Int) -> [MapChapter] {
        var defined = MapChapter.standard.filter { $0.range.lowerBound <= levelCount }
        defined = defined.map { chapter in
            let lo = chapter.range.lowerBound
            let hi = min(chapter.range.upperBound, levelCount)
            return MapChapter(range: lo...hi, title: chapter.title, subtitle: chapter.subtitle)
        }
        var next = (defined.last?.range.upperBound ?? 0) + 1
        var world = defined.count + 1
        while next <= levelCount {
            let hi = min(next + 24, levelCount)
            defined.append(MapChapter(range: next...hi, title: "World \(world)", subtitle: "New Horizon"))
            next = hi + 1
            world += 1
        }
        return defined
    }

    private static func chapterIndex(for id: Int, chapters: [MapChapter]) -> Int {
        chapters.firstIndex(where: { $0.range.contains(id) }) ?? 0
    }

    private static func hashJitter(_ levelID: Int) -> Double {
        var x = UInt64(levelID) &* 0x9E3779B97F4A7C15 &+ patternSeed
        x ^= x >> 30
        x = x &* 0xBF58476D1CE4E5B9
        x ^= x >> 27
        let unit = Double(x % 10_000) / 10_000.0
        return unit * 2 - 1
    }
}

struct MapChapter: Equatable, Sendable {
    let range: ClosedRange<Int>
    let title: String
    let subtitle: String

    static let standard: [MapChapter] = [
        MapChapter(range: 1...20, title: "World 1", subtitle: "Dawn Meadows"),
        MapChapter(range: 21...40, title: "World 2", subtitle: "Sky Isles"),
        MapChapter(range: 41...60, title: "World 3", subtitle: "Twilight Groves"),
        MapChapter(range: 61...80, title: "World 4", subtitle: "Ember Ridges"),
        MapChapter(range: 81...100, title: "World 5", subtitle: "Moonlit Peaks"),
        MapChapter(range: 101...125, title: "World 6", subtitle: "Aurora Fields"),
        MapChapter(range: 126...150, title: "World 7", subtitle: "Crystal Canyons"),
        MapChapter(range: 151...175, title: "World 8", subtitle: "Starfall Basin"),
        MapChapter(range: 176...200, title: "World 9", subtitle: "Horizon's End")
    ]
}
