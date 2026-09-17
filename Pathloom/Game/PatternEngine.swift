import Foundation

struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

struct LevelSpec: Sendable {
    var id: Int
    var difficulty: Difficulty
    var archetype: PuzzlePattern
    var secondaries: [PuzzlePattern]
    var gridSize: Int
    var arrowCount: Int
    var targetDepth: ClosedRange<Int>
    var targetInitial: ClosedRange<Int>
    var minScore: Double
    var seed: Int
    var candidateBudget: Int

    var pattern: PuzzlePattern { archetype }

    init(
        id: Int,
        difficulty: Difficulty,
        archetype: PuzzlePattern,
        secondaries: [PuzzlePattern] = [],
        gridSize: Int,
        arrowCount: Int,
        targetDepth: ClosedRange<Int>,
        targetInitial: ClosedRange<Int>,
        minScore: Double,
        seed: Int,
        candidateBudget: Int = 36
    ) {
        self.id = id
        self.difficulty = difficulty
        self.archetype = archetype
        self.secondaries = secondaries
        self.gridSize = gridSize
        self.arrowCount = arrowCount
        self.targetDepth = targetDepth
        self.targetInitial = targetInitial
        self.minScore = minScore
        self.seed = seed
        self.candidateBudget = candidateBudget
    }
}

enum PatternEngine {
    struct ScoredCandidate {
        var level: Level
        var analysis: LevelAnalysis
        var quality: Double
    }

    static func generate(spec: LevelSpec, previous: [Level] = []) -> Level? {
        var rng = SplitMix64(seed: UInt64(bitPattern: Int64(spec.seed)))
        let previousPrints = previous.suffix(3).map { LevelSimilarity.fingerprint($0) }
        var best: ScoredCandidate?
        let budget = max(12, spec.candidateBudget)

        for attempt in 0..<budget {
            var attemptRNG = SplitMix64(seed: UInt64(bitPattern: Int64(spec.seed &+ attempt &* 1_013)) &+ rng.next())
            guard let draft = makeDraft(spec: spec, attempt: attempt, rng: &attemptRNG) else { continue }
            let analysis = LevelAnalyzer.analyze(draft)
            if analysis.issues.contains(where: { ["Unsolvable", "Overlapping arrows", "Out of bounds", "Empty board"].contains($0) }) {
                continue
            }

            let relax = attempt > budget * 2 / 3
            if !passesTargets(analysis, spec: spec, relax: relax) { continue }

            let fingerprint = LevelSimilarity.fingerprint(draft, analysis: analysis)
            if previousPrints.contains(where: { LevelSimilarity.tooSimilar(fingerprint, $0) }) {
                continue
            }

            let quality = PatternQuality.score(analysis: analysis, spec: spec, previous: previous)
            if quality < (relax ? 2.2 : spec.id <= 10 ? 1.5 : 3.0) { continue }

            let stamped = stamp(draft, spec: spec, analysis: analysis)
            let scored = ScoredCandidate(level: stamped, analysis: analysis, quality: quality)
            if best == nil || scored.quality > best!.quality + 0.05
                || (abs(scored.quality - best!.quality) <= 0.05 && closerDifficulty(scored.analysis, spec: spec, than: best!.analysis)) {
                best = scored
            }
            if scored.quality >= 7.5 && passesTargets(analysis, spec: spec, relax: false) {
                break
            }
        }

        return best?.level
    }

    private static func makeDraft(spec: LevelSpec, attempt: Int, rng: inout SplitMix64) -> Level? {
        let graph = DependencyGraphFactory.build(
            pattern: spec.pattern,
            secondaries: spec.secondaries,
            nodeCount: spec.arrowCount,
            rng: &rng
        )
        let formation = PatternLayout.formation(for: spec.pattern, attempt: attempt, rng: &rng)
        let transform = Int(rng.next() % 8)
        guard let placed = PatternLayout.realize(
            graph: graph,
            gridSize: spec.gridSize,
            formation: formation,
            transform: transform,
            rng: &rng
        ) else { return nil }

        var arrows = placed.map(\.data)
        if arrows.count > spec.arrowCount {
            arrows = Array(arrows.prefix(spec.arrowCount))
        }
        guard arrows.count >= max(1, spec.arrowCount - 2) else { return nil }

        return Level(
            id: spec.id,
            gridSize: spec.gridSize,
            parMoves: arrows.count,
            difficulty: spec.difficulty,
            arrows: reindex(arrows),
            seed: spec.seed + attempt,
            archetype: spec.pattern.rawValue,
            patternType: spec.pattern.rawValue,
            patternFamily: spec.pattern.family.rawValue
        )
    }

    private static func reindex(_ arrows: [ArrowData]) -> [ArrowData] {
        arrows.enumerated().map { index, arrow in
            ArrowData(id: index + 1, row: arrow.row, column: arrow.column, direction: arrow.direction)
        }
    }

    static func finalize(_ level: Level, spec: LevelSpec) -> Level? {
        let analysis = LevelAnalyzer.analyze(level)
        if analysis.issues.contains("Unsolvable") { return nil }
        return stamp(level, spec: spec, analysis: analysis)
    }

    static func stamp(_ level: Level, spec: LevelSpec, analysis: LevelAnalysis) -> Level {
        let pattern = PuzzlePattern(rawValue: level.resolvedPatternType) ?? spec.pattern
        return Level(
            id: spec.id,
            gridSize: level.gridSize,
            parMoves: analysis.optimalMoves,
            difficulty: spec.difficulty,
            arrows: level.arrows,
            seed: level.seed,
            archetype: pattern.rawValue,
            patternType: pattern.rawValue,
            patternFamily: pattern.family.rawValue,
            difficultyScore: (analysis.difficultyScore * 10).rounded() / 10,
            solutionDepth: analysis.solutionDepth,
            branchingFactor: analysis.branches,
            bottleneckCount: analysis.bottlenecks,
            clusterCount: analysis.clusters
        )
    }

    private static func passesTargets(_ analysis: LevelAnalysis, spec: LevelSpec, relax: Bool) -> Bool {
        if analysis.initialValidMoves < 1 { return false }
        if spec.arrowCount > 4 && analysis.dependencyCount == 0 { return false }
        if spec.id >= 15 {
            if analysis.distinctDirections < 2 { return false }
            if analysis.distinctDirections == 1 { return false }
        }
        if relax {
            return analysis.solutionDepth >= max(1, spec.targetDepth.lowerBound - 3)
        }
        if analysis.solutionDepth < spec.targetDepth.lowerBound { return false }
        if analysis.solutionDepth > spec.targetDepth.upperBound + 4 { return false }
        if analysis.initialValidMoves < spec.targetInitial.lowerBound { return false }
        if analysis.initialValidMoves > spec.targetInitial.upperBound + 2 { return false }
        if analysis.difficultyScore + 1.8 < spec.minScore { return false }
        return true
    }

    private static func closerDifficulty(_ a: LevelAnalysis, spec: LevelSpec, than b: LevelAnalysis) -> Bool {
        abs(a.difficultyScore - spec.minScore) < abs(b.difficultyScore - spec.minScore)
    }
}

enum PatternQuality {
    static func score(analysis: LevelAnalysis, spec: LevelSpec, previous: [Level]) -> Double {
        var value = 0.0
        if analysis.passed { value += 2.0 }
        value += min(2.0, Double(analysis.dependencyCount) / 10.0)
        value += min(1.5, Double(analysis.solutionDepth) / 8.0)
        value += analysis.distinctDirections >= 4 ? 1.2 : (analysis.distinctDirections >= 3 ? 0.8 : 0.1)
        if (1...4).contains(analysis.initialValidMoves) { value += 1.0 }
        if analysis.density >= 0.10 && analysis.density <= 0.55 { value += 1.0 }
        value += min(1.0, Double(analysis.branches) / 4.0)
        if spec.pattern.family == .cluster || spec.pattern.family == .hybrid {
            value += analysis.clusters >= 2 ? 0.6 : 0
        }
        if analysis.difficultyScore + 0.8 >= spec.minScore { value += 0.6 }
        if let last = previous.last, last.resolvedPatternType == analysis.pattern {
            value -= 0.35
        }
        return min(10, max(0, value))
    }
}
