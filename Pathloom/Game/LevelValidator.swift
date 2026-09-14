import Foundation

enum LevelValidator {
    static func validate(_ level: Level, previous: [Level] = []) -> [String] {
        var issues = LevelAnalyzer.analyze(level).issues
        if level.gridSize < 2 {
            issues.append("Grid too small")
        }
        if level.parMoves != level.arrowCount {
            if LevelSolver.solve(level: level)?.count != level.parMoves {
                issues.append("parMoves does not match solver")
            }
        }
        let density = LevelGraph.density(level)
        if density > 0.72 {
            issues.append("Density too high")
        }
        if level.id > 1 && density < 0.04 && level.arrowCount > 2 {
            issues.append("Density too low")
        }
        let histogram = LevelGraph.directionHistogram(level)
        if level.id >= 15 {
            let used = histogram.values.filter { $0 > 0 }.count
            if used < 3 {
                issues.append("Too few directions")
            }
        }
        let print = LevelSimilarity.fingerprint(level)
        for prior in previous.suffix(5) {
            if LevelSimilarity.tooSimilar(print, LevelSimilarity.fingerprint(prior)) {
                issues.append("Too similar to level \(prior.id)")
            }
        }
        return issues
    }

    static func report(for catalog: [Level]) -> String {
        var lines: [String] = []
        var failures: [Int] = []
        for (index, level) in catalog.enumerated() {
            let previous = Array(catalog.prefix(index))
            let analysis = LevelAnalyzer.analyze(level)
            let issues = validate(level, previous: previous)
            let status = issues.isEmpty ? "PASS" : "FAIL \(issues.joined(separator: "; "))"
            if !issues.isEmpty { failures.append(level.id) }
            lines.append(
                String(
                    format: "Level %d: %@ | %@ | diff %.1f | arrows %d | %dx%d | opt %d | depth %d | init %d | %@",
                    level.id,
                    status,
                    analysis.pattern,
                    analysis.difficultyScore,
                    analysis.arrows,
                    analysis.gridSize,
                    analysis.gridSize,
                    analysis.optimalMoves,
                    analysis.solutionDepth,
                    analysis.initialValidMoves,
                    analysis.difficultyTier.rawValue
                )
            )
        }
        if failures.isEmpty {
            lines.append("All \(catalog.count) levels PASS.")
        } else {
            lines.append("Failed: \(failures.map(String.init).joined(separator: ", "))")
        }
        return lines.joined(separator: "\n")
    }
}
