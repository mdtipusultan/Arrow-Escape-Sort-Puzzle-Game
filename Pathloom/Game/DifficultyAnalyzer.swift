import Foundation

enum DifficultyAnalyzer {
    static func analyze(_ level: Level) -> LevelAnalysis {
        LevelAnalyzer.analyze(level)
    }

    static func meetsIntent(_ analysis: LevelAnalysis, spec: LevelSpec, relax: Bool = false) -> Bool {
        if !analysis.passed && analysis.issues.contains("Unsolvable") { return false }
        if analysis.initialValidMoves < 1 { return false }
        if spec.arrowCount > 4 && analysis.dependencyCount == 0 { return false }

        let depthFloor = relax ? max(1, spec.targetDepth.lowerBound - (spec.id >= 61 ? 1 : 2)) : spec.targetDepth.lowerBound
        if analysis.solutionDepth < depthFloor { return false }
        if !relax && analysis.solutionDepth > spec.targetDepth.upperBound + 6 { return false }

        let initialFloor = spec.targetInitial.lowerBound
        let initialCeil = spec.targetInitial.upperBound + (relax ? 2 : 1)
        if analysis.initialValidMoves < initialFloor { return false }
        if analysis.initialValidMoves > initialCeil { return false }

        let scoreFloor = spec.minScore - (relax ? (spec.id >= 81 ? 0.4 : 1.0) : 0)
        if analysis.difficultyScore + 0.05 < scoreFloor { return false }

        if spec.id >= 21 && analysis.distinctDirections < 2 { return false }
        if spec.id >= 41 && analysis.distinctDirections < 3 { return false }

        if spec.id >= 21 && analysis.bottlenecks < 1 && spec.pattern.family != .chain {
            if !relax { return false }
        }
        if spec.id >= 61 && analysis.bottlenecks < 2 && spec.pattern.family != .chain {
            if !relax { return false }
        }
        if spec.id >= 81 && analysis.difficultyScore < spec.minScore - 0.2 {
            return false
        }
        if spec.id >= 41 && analysis.arrows + 4 < spec.arrowCount {
            return false
        }
        return true
    }

    static func isTrivialForLateGame(_ analysis: LevelAnalysis, spec: LevelSpec) -> Bool {
        spec.id >= 80 && (analysis.difficultyScore < spec.minScore - 0.8 || analysis.solutionDepth < 8 || analysis.initialValidMoves > 5)
    }
}
