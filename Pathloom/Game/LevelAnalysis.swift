import Foundation

struct LevelAnalysis: Sendable, Equatable {
    var levelID: Int
    var pattern: String
    var difficultyScore: Double
    var arrows: Int
    var gridSize: Int
    var optimalMoves: Int
    var solutionDepth: Int
    var initialValidMoves: Int
    var branches: Int
    var bottlenecks: Int
    var clusters: Int
    var difficultyTier: Difficulty
    var nodesExpanded: Int
    var density: Double
    var dependencyCount: Int
    var distinctDirections: Int
    var patternQualityScore: Double
    var passed: Bool
    var issues: [String]
}

enum LevelAnalyzer {
    static func analyze(_ level: Level) -> LevelAnalysis {
        let edges = LevelGraph.blockingAdjacency(level)
        let report = LevelSolver.report(level: level)
        var issues: [String] = []

        if LevelGraph.hasOverlaps(level) {
            issues.append("Overlapping arrows")
        }
        if LevelGraph.hasOutOfBounds(level) {
            issues.append("Out of bounds")
        }
        if report == nil {
            issues.append("Unsolvable")
        }
        if level.arrows.isEmpty {
            issues.append("Empty board")
        }

        let depth = report?.solutionDepth ?? LevelGraph.longestChain(edges)
        let initial = report?.initialMoveCount ?? LevelGraph.initialMoveIDs(level).count
        let branches = LevelGraph.branchCount(edges)
        let bottlenecks = LevelGraph.bottleneckCount(edges)
        let deps = LevelGraph.dependencyCount(edges)
        let density = LevelGraph.density(level)
        let clusters = LevelGraph.clusterCount(level)
        let expanded = report?.nodesExpanded ?? 0
        let histogram = LevelGraph.directionHistogram(level)
        let distinctDirectionCount = histogram.values.filter { $0 > 0 }.count
        let misleading = max(0, initial - 1)

        let score = difficultyScore(
            arrows: level.arrowCount,
            density: density,
            dependencies: deps,
            longestChain: depth,
            branches: branches,
            bottlenecks: bottlenecks,
            initialMoves: initial,
            misleading: misleading,
            solutionDepth: depth,
            nodesExpanded: expanded,
            distinctDirections: distinctDirectionCount
        )

        if level.arrowCount > 1 && deps == 0 {
            issues.append("No dependencies")
        }
        if level.id >= 15 {
            let maxDir = histogram.values.max() ?? 0
            if Double(maxDir) / Double(max(level.arrowCount, 1)) > 0.88 {
                issues.append("Direction monopoly")
            }
            if distinctDirectionCount < 2 {
                issues.append("Too few directions")
            }
        }
        if density > 0.72 {
            issues.append("Density too high")
        }

        let quality = min(10, max(0,
            (report != nil ? 2 : 0) +
            min(2, Double(deps) / 10) +
            min(1.5, Double(depth) / 8) +
            (distinctDirectionCount >= 3 ? 1 : 0) +
            ((1...4).contains(initial) ? 1 : 0) +
            ((0.1...0.55).contains(density) ? 1 : 0) +
            min(1, Double(branches) / 4)
        ))

        return LevelAnalysis(
            levelID: level.id,
            pattern: level.resolvedPatternType,
            difficultyScore: score,
            arrows: level.arrowCount,
            gridSize: level.gridSize,
            optimalMoves: report?.optimalMoves ?? level.parMoves,
            solutionDepth: depth,
            initialValidMoves: initial,
            branches: branches,
            bottlenecks: bottlenecks,
            clusters: clusters,
            difficultyTier: level.difficulty,
            nodesExpanded: expanded,
            density: density,
            dependencyCount: deps,
            distinctDirections: distinctDirectionCount,
            patternQualityScore: (quality * 10).rounded() / 10,
            passed: issues.isEmpty && report != nil,
            issues: issues
        )
    }

    static func difficultyScore(
        arrows: Int,
        density: Double,
        dependencies: Int,
        longestChain: Int,
        branches: Int,
        bottlenecks: Int,
        initialMoves: Int,
        misleading: Int,
        solutionDepth: Int,
        nodesExpanded: Int,
        distinctDirections: Int
    ) -> Double {
        func clamp01(_ value: Double) -> Double { min(max(value, 0), 1) }
        func norm(_ value: Double, _ lo: Double, _ hi: Double) -> Double {
            guard hi > lo else { return 0 }
            return clamp01((value - lo) / (hi - lo))
        }

        let initialPenalty = 1 - norm(Double(initialMoves), 1, 5)
        let search = log(Double(max(nodesExpanded, 1))) / log(8_000)
        let weighted =
            0.08 * norm(Double(arrows), 4, 45) +
            0.08 * clamp01(density / 0.55) +
            0.14 * norm(Double(dependencies), 1, 48) +
            0.18 * norm(Double(longestChain), 1, 24) +
            0.10 * norm(Double(branches), 0, 12) +
            0.14 * norm(Double(bottlenecks), 0, 5) +
            0.12 * initialPenalty +
            0.04 * norm(Double(misleading), 0, 4) +
            0.08 * norm(Double(solutionDepth), 1, 24) +
            0.04 * clamp01(search)

        let directionBonus = distinctDirections >= 4 ? 0.18 : (distinctDirections >= 3 ? 0.10 : 0)
        let lockBonus = initialMoves == 1 && longestChain >= 8 ? 0.22 : 0
        return min(10, (weighted * 9.35) + directionBonus + lockBonus)
    }
}
