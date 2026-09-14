import Foundation

enum LevelSimilarity {
    struct Fingerprint: Equatable {
        var gridSize: Int
        var arrowCount: Int
        var archetype: String
        var directions: [Int]
        var occupancyHash: Int
        var depth: Int
        var initialMoves: Int
        var scoreBucket: Int
    }

    static func fingerprint(_ level: Level, analysis: LevelAnalysis? = nil) -> Fingerprint {
        let analyzed = analysis ?? LevelAnalyzer.analyze(level)
        let histogram = LevelGraph.directionHistogram(level)
        let directions = [histogram[.up] ?? 0, histogram[.down] ?? 0, histogram[.left] ?? 0, histogram[.right] ?? 0]
        return Fingerprint(
            gridSize: level.gridSize,
            arrowCount: level.arrowCount,
            archetype: level.archetype ?? analyzed.pattern,
            directions: directions,
            occupancyHash: occupancyHash(level),
            depth: analyzed.solutionDepth,
            initialMoves: analyzed.initialValidMoves,
            scoreBucket: Int((analyzed.difficultyScore * 2).rounded())
        )
    }

    static func tooSimilar(_ a: Fingerprint, _ b: Fingerprint) -> Bool {
        if a.archetype == b.archetype && a.gridSize == b.gridSize && a.arrowCount == b.arrowCount {
            if a.directions == b.directions { return true }
            if a.occupancyHash == b.occupancyHash { return true }
            if a.depth == b.depth && a.initialMoves == b.initialMoves && abs(a.scoreBucket - b.scoreBucket) <= 1 {
                return true
            }
        }
        if a.archetype == b.archetype && a.gridSize == b.gridSize && abs(a.arrowCount - b.arrowCount) <= 1 {
            let dirDelta = zip(a.directions, b.directions).reduce(0) { $0 + abs($1.0 - $1.1) }
            if dirDelta <= 1 && a.depth == b.depth { return true }
        }
        return false
    }

    private static func occupancyHash(_ level: Level) -> Int {
        var hash = 5381
        let arrows = level.arrows.sorted {
            if $0.row != $1.row { return $0.row < $1.row }
            if $0.column != $1.column { return $0.column < $1.column }
            return $0.direction.rawValue < $1.direction.rawValue
        }
        for arrow in arrows {
            hash = ((hash << 5) &+ hash) &+ arrow.row
            hash = ((hash << 5) &+ hash) &+ arrow.column
            hash = ((hash << 5) &+ hash) &+ directionIndex(arrow.direction)
        }
        hash = ((hash << 5) &+ hash) &+ level.gridSize
        return hash
    }

    private static func directionIndex(_ direction: Direction) -> Int {
        switch direction {
        case .up: 1
        case .right: 2
        case .down: 3
        case .left: 4
        }
    }
}
