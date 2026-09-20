import Foundation

enum LevelProgression {
    static func spec(for id: Int, previousPattern: PuzzlePattern? = nil) -> LevelSpec {
        let tier = tier(for: id)
        var pattern = specialPattern(for: id) ?? rotatedPattern(for: id, familyPool: tier.pool)
        if pattern == previousPattern {
            let pool = tier.pool
            if let idx = pool.firstIndex(of: pattern) {
                pattern = pool[(idx + 1) % pool.count]
            }
        }
        let secondaries = hybridSecondaries(for: id, primary: pattern)
        let wave = waveAdjustment(for: id)
        let arrows = clamp(tier.arrows.lowerBound + wave.arrows, tier.arrows.lowerBound, tier.arrows.upperBound)
        let grid = clamp(tier.grid.lowerBound + wave.grid, tier.grid.lowerBound, tier.grid.upperBound)
        let fittedGrid = max(grid, minimumGrid(for: arrows))
        let depthLow = max(1, tier.depth.lowerBound + wave.depth)
        let depthHigh = max(depthLow, tier.depth.upperBound + wave.depth)

        return LevelSpec(
            id: id,
            difficulty: tier.difficulty,
            archetype: pattern,
            secondaries: secondaries,
            gridSize: fittedGrid,
            arrowCount: min(arrows, fittedGrid * fittedGrid - 1),
            targetDepth: depthLow...depthHigh,
            targetInitial: tier.initial,
            minScore: max(0, tier.minScore + wave.score),
            seed: 70_000 + id * 131,
            candidateBudget: id <= 10 ? 12 : (id % 10 == 0 ? 40 : 28)
        )
    }

    static func specialPattern(for id: Int) -> PuzzlePattern? {
        switch id {
        case 10: .branchingTree
        case 20: .singleBottleneck
        case 30: .crossLock
        case 40: .dualCluster
        case 50: .deepLock
        case 60: .bridgePattern
        case 70: .multiBottleneck
        case 80: .deepBranch
        case 90: .dependencyWeb
        case 100: .expertHybrid
        case 110: .intersectionLock
        case 120: .tripleCluster
        case 130: .longChain
        case 140: .clusterBridge
        case 150: .masterHybrid
        case 160: .complexAsymmetric
        case 170: .multiStageUnlock
        case 180: .dependencyWeb
        case 190: .masterHybrid
        case 200: .masterHybrid
        default: nil
        }
    }

    private struct Tier {
        var difficulty: Difficulty
        var arrows: ClosedRange<Int>
        var grid: ClosedRange<Int>
        var depth: ClosedRange<Int>
        var initial: ClosedRange<Int>
        var minScore: Double
        var pool: [PuzzlePattern]
    }

    private static func tier(for id: Int) -> Tier {
        let chain: [PuzzlePattern] = [
            .simpleChain, .reverseChain, .longChain, .doubleChain, .parallelChains,
            .interlockingChains, .zigzagChain, .brokenChain, .alternatingDirectionChain, .nestedChain
        ]
        let branch: [PuzzlePattern] = [
            .binaryBranch, .tripleBranch, .wideBranch, .deepBranch, .branchMerge,
            .multipleBranches, .asymmetricBranch, .branchingTree
        ]
        let bottleneck: [PuzzlePattern] = [
            .singleBottleneck, .doubleBottleneck, .centralBottleneck, .edgeBottleneck,
            .hiddenBottleneck, .multiStageBottleneck
        ]
        let cross: [PuzzlePattern] = [
            .crossLock, .doubleCross, .horizontalVerticalLock, .intersectionLock, .crossBranch, .crossBottleneck
        ]
        let cluster: [PuzzlePattern] = [
            .dualCluster, .tripleCluster, .connectedClusters, .isolatedClusters, .clusterBridge, .nestedClusters
        ]
        let advanced: [PuzzlePattern] = [
            .bridgePattern, .deepLock, .multiBottleneck, .dependencyWeb, .convergingDependencies,
            .divergingDependencies, .multiStageUnlock, .complexAsymmetric
        ]

        switch id {
        case 1...10:
            return Tier(
                difficulty: id <= 3 ? .tutorial : .easy,
                arrows: id <= 3 ? 1...4 : 4...8,
                grid: 3...5,
                depth: 1...4,
                initial: 1...3,
                minScore: 0.5,
                pool: [.simpleChain, .reverseChain, .binaryBranch, .singleBottleneck, .zigzagChain, .brokenChain]
            )
        case 11...20:
            return Tier(
                difficulty: .medium,
                arrows: 7...12,
                grid: 5...6,
                depth: 4...7,
                initial: 1...3,
                minScore: 2.6,
                pool: chain + [.binaryBranch, .tripleBranch, .singleBottleneck, .crossLock]
            )
        case 21...40:
            return Tier(
                difficulty: .hard,
                arrows: 10...18,
                grid: 6...8,
                depth: 6...10,
                initial: id % 2 == 0 ? 1...1 : 1...2,
                minScore: 4.8,
                pool: branch + bottleneck + [.crossLock, .dualCluster, .bridgePattern, .doubleChain]
            )
        case 41...60:
            return Tier(
                difficulty: .veryHard,
                arrows: 15...24,
                grid: 7...9,
                depth: 8...14,
                initial: id % 3 == 0 ? 1...1 : 1...2,
                minScore: 6.0,
                pool: bottleneck + cross + cluster + [.deepLock, .longChain, .clusterBridge]
            )
        case 61...80:
            return Tier(
                difficulty: .expert,
                arrows: 18...30,
                grid: 8...10,
                depth: 10...18,
                initial: id % 3 == 0 ? 1...1 : 1...2,
                minScore: 7.0,
                pool: advanced + cross + cluster + [.deepBranch, .multiBottleneck]
            )
        case 81...100:
            return Tier(
                difficulty: .extreme,
                arrows: 22...35,
                grid: 8...10,
                depth: 12...20,
                initial: id % 2 == 0 ? 1...1 : 1...2,
                minScore: 7.8,
                pool: advanced + cross + cluster + [.deepBranch, .dependencyWeb, .expertHybrid]
            )
        case 101...150:
            return Tier(
                difficulty: .master,
                arrows: 25...40,
                grid: 9...11,
                depth: 15...25,
                initial: 1...2,
                minScore: 8.4,
                pool: advanced + cross + cluster + branch + [.expertHybrid, .masterHybrid]
            )
        default:
            return Tier(
                difficulty: .challenge,
                arrows: 30...45,
                grid: 9...11,
                depth: 18...28,
                initial: 1...2,
                minScore: 8.8,
                pool: advanced + [.expertHybrid, .masterHybrid, .dependencyWeb, .complexAsymmetric, .tripleCluster]
            )
        }
    }

    private static func rotatedPattern(for id: Int, familyPool: [PuzzlePattern]) -> PuzzlePattern {
        let pool = familyPool.isEmpty ? PuzzlePattern.allCases : familyPool
        return pool[(id * 3 + id / 4) % pool.count]
    }

    private static func hybridSecondaries(for id: Int, primary: PuzzlePattern) -> [PuzzlePattern] {
        switch id {
        case 21...60:
            let extras: [PuzzlePattern] = [.crossLock, .singleBottleneck, .dualCluster]
            return [extras[id % extras.count]].filter { $0 != primary }
        case 61...100:
            let extras: [PuzzlePattern] = [.crossLock, .bridgePattern, .deepBranch, .clusterBridge]
            return [extras[id % extras.count]].filter { $0 != primary }
        case 101...150:
            let extras: [PuzzlePattern] = [.crossLock, .singleBottleneck, .dualCluster, .bridgePattern, .deepBranch]
            return [extras[id % extras.count]].filter { $0 != primary }
        case 151...200:
            let extras: [PuzzlePattern] = [.crossLock, .clusterBridge, .multiBottleneck, .longChain, .dependencyWeb]
            let a = extras[id % extras.count]
            let b = extras[(id * 3) % extras.count]
            return [a, b].filter { $0 != primary }
        default:
            return []
        }
    }

    private static func waveAdjustment(for id: Int) -> (arrows: Int, grid: Int, depth: Int, score: Double) {
        let mod = id % 10
        if id <= 10 { return (max(0, id - 4), 0, 0, 0) }
        if mod == 0 { return (5, 1, 3, 0.6) }
        if id >= 21 {
            if mod == 1 { return (0, 0, 0, 0) }
            if mod == 4 { return (1, 0, 1, 0.1) }
            if mod == 5 { return (2, 0, 1, 0.2) }
            if mod == 8 { return (3, 1, 2, 0.35) }
            if mod == 9 { return (1, 0, 1, 0.1) }
            return (mod / 4, 0, 0, 0)
        }
        if mod == 1 { return (-2, 0, -1, -0.3) }
        if mod == 4 { return (-1, 0, 0, -0.1) }
        if mod == 5 { return (2, 0, 1, 0.2) }
        if mod == 8 { return (3, 1, 1, 0.35) }
        if mod == 9 { return (-1, 0, 0, -0.1) }
        return (mod / 3, 0, 0, 0)
    }

    private static func minimumGrid(for arrows: Int) -> Int {
        var grid = 4
        while grid * grid < Int(Double(arrows) / 0.40) + 1 {
            grid += 1
        }
        return min(grid, 11)
    }

    private static func clamp(_ value: Int, _ lo: Int, _ hi: Int) -> Int {
        min(max(value, lo), hi)
    }
}

enum LevelCatalogBuilder {
    static func buildCatalog(count: Int = AppConstants.totalLevels) -> [Level] {
        var levels: [Level] = []
        var previousPattern: PuzzlePattern?
        for id in 1...count {
            if id == 1 || id % 10 == 0 {
                fputs("Generating level \(id)/\(count)\n", stderr)
            }
            let spec = LevelProgression.spec(for: id, previousPattern: previousPattern)
            var level = LevelGenerator.generate(spec: spec, previous: levels)
                ?? LevelGenerator.guaranteedLevel(spec: spec)

            var issues = LevelValidator.validate(level, previous: levels)
            if !issues.isEmpty {
                var retrySpec = spec
                retrySpec.candidateBudget = 32
                for extra in 1...8 {
                    retrySpec.seed = spec.seed + extra * 17_771
                    if let rebuilt = PuzzleConstructor.build(spec: retrySpec, previous: levels) {
                        let rebuiltIssues = LevelValidator.validate(rebuilt, previous: levels)
                        if rebuiltIssues.isEmpty {
                            level = rebuilt
                            issues = rebuiltIssues
                            break
                        }
                        if rebuiltIssues.count < issues.count {
                            level = rebuilt
                            issues = rebuiltIssues
                        }
                    }
                }
            }
            if !issues.isEmpty || LevelSolver.solve(level: level) == nil || DifficultyAnalyzer.isTrivialForLateGame(LevelAnalyzer.analyze(level), spec: spec) {
                if let constructed = PuzzleConstructor.build(spec: spec, previous: levels) {
                    let constructedIssues = LevelValidator.validate(constructed, previous: levels)
                    if constructedIssues.isEmpty || LevelSolver.solve(level: level) == nil {
                        level = constructed
                    }
                } else {
                    let fallback = LevelGenerator.guaranteedLevel(spec: spec)
                    if let finished = PatternEngine.finalize(fallback, spec: spec),
                       LevelSolver.solve(level: finished) != nil {
                        let fallbackIssues = LevelValidator.validate(finished, previous: levels)
                        if fallbackIssues.isEmpty || LevelSolver.solve(level: level) == nil {
                            level = finished
                        }
                    }
                }
            }

            levels.append(level)
            previousPattern = PuzzlePattern(rawValue: level.resolvedPatternType) ?? spec.pattern
        }
        return levels
    }

    static func jsonData(count: Int = AppConstants.totalLevels) throws -> Data {
        let catalog = LevelCatalog(levels: buildCatalog(count: count))
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(catalog)
    }
}
