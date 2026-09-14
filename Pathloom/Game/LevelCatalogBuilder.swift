import Foundation

enum LevelProgression {
    static func spec(for id: Int, previousArchetype: LevelArchetype? = nil) -> LevelSpec {
        let tier = tier(for: id)
        var archetype = specialArchetype(for: id) ?? rotatedArchetype(for: id)
        if archetype == previousArchetype {
            let all = LevelArchetype.allCases
            if let idx = all.firstIndex(of: archetype) {
                archetype = all[(idx + 1) % all.count]
            }
        }

        let wave = waveAdjustment(for: id)
        let arrows = clamp(tier.arrows.lowerBound + wave.arrows, tier.arrows.lowerBound, tier.arrows.upperBound)
        let grid = clamp(tier.grid.lowerBound + wave.grid, tier.grid.lowerBound, tier.grid.upperBound)
        let fittedGrid = max(grid, minimumGrid(for: arrows))
        let depthLow = max(1, tier.depth.lowerBound + wave.depth)
        let depthHigh = max(depthLow, tier.depth.upperBound + wave.depth)
        let initial = tier.initial

        return LevelSpec(
            id: id,
            difficulty: tier.difficulty,
            archetype: archetype,
            gridSize: fittedGrid,
            arrowCount: min(arrows, fittedGrid * fittedGrid - 1),
            targetDepth: depthLow...depthHigh,
            targetInitial: initial,
            minScore: max(0, tier.minScore + wave.score),
            seed: 50_000 + id * 97
        )
    }

    static func specialArchetype(for id: Int) -> LevelArchetype? {
        switch id {
        case 10: .branchingTree
        case 20: .bottleneck
        case 30: .crossDependency
        case 40: .multiCluster
        case 50: .chainReaction
        case 60: .bridge
        case 70: .deepLock
        case 80: .expertChallenge
        case 90: .doubleBottleneck
        case 100: .expertChallenge
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
    }

    private static func tier(for id: Int) -> Tier {
        switch id {
        case 1...10:
            return Tier(difficulty: id <= 3 ? .tutorial : .easy, arrows: 4...7, grid: 3...5, depth: 1...3, initial: 1...3, minScore: 0.6)
        case 11...25:
            return Tier(difficulty: .easy, arrows: 7...12, grid: 5...6, depth: 3...5, initial: 1...3, minScore: 2.0)
        case 26...40:
            return Tier(difficulty: .medium, arrows: 10...16, grid: 6...7, depth: 4...7, initial: 1...4, minScore: 3.4)
        case 41...60:
            return Tier(difficulty: .hard, arrows: 14...22, grid: 7...8, depth: 6...9, initial: 1...3, minScore: 4.6)
        case 61...80:
            return Tier(difficulty: .veryHard, arrows: 18...28, grid: 8...9, depth: 7...12, initial: 1...4, minScore: 5.8)
        case 81...95:
            return Tier(difficulty: .expert, arrows: 22...32, grid: 8...10, depth: 9...15, initial: 1...3, minScore: 6.8)
        default:
            return Tier(difficulty: .challenge, arrows: 25...36, grid: 9...10, depth: 10...16, initial: 1...3, minScore: 7.4)
        }
    }

    private static func rotatedArchetype(for id: Int) -> LevelArchetype {
        let all = LevelArchetype.allCases
        return all[(id * 7 + 3) % all.count]
    }

    private static func waveAdjustment(for id: Int) -> (arrows: Int, grid: Int, depth: Int, score: Double) {
        let mod = id % 10
        if id <= 10 { return (max(0, id - 4), 0, 0, 0) }
        if mod == 0 { return (4, 1, 2, 0.8) }
        if mod == 1 { return (-3, 0, -2, -0.7) }
        if mod == 5 { return (2, 0, 1, 0.3) }
        if mod == 8 { return (3, 1, 1, 0.5) }
        return (mod / 3, 0, 0, 0)
    }

    private static func minimumGrid(for arrows: Int) -> Int {
        var grid = 4
        while grid * grid < Int(Double(arrows) / 0.48) + 1 {
            grid += 1
        }
        return min(grid, 10)
    }

    private static func clamp(_ value: Int, _ lo: Int, _ hi: Int) -> Int {
        min(max(value, lo), hi)
    }
}

enum LevelCatalogBuilder {
    static func buildCatalog(count: Int = AppConstants.totalLevels) -> [Level] {
        var levels: [Level] = []
        var previousArchetype: LevelArchetype?
        for id in 1...count {
            let spec = LevelProgression.spec(for: id, previousArchetype: previousArchetype)
            if let level = LevelGenerator.generate(spec: spec, previous: levels) {
                levels.append(level)
                previousArchetype = LevelArchetype(rawValue: level.archetype ?? "") ?? spec.archetype
            } else {
                let fallback = LevelGenerator.guaranteedLevel(spec: spec)
                if let finished = LevelGenerator.generate(spec: spec, previous: []) {
                    levels.append(finished)
                } else {
                    levels.append(fallback)
                }
                previousArchetype = spec.archetype
            }
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
