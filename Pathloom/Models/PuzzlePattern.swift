import Foundation

enum PatternFamily: String, Codable, CaseIterable, Sendable {
    case chain
    case branching
    case bottleneck
    case cross
    case cluster
    case advanced
    case hybrid

    var displayName: String {
        rawValue.capitalized
    }
}

enum DirectionStrategy: String, Sendable {
    case aligned
    case alternating
    case mixed
    case intersecting
    case radial
}

enum PuzzlePattern: String, Codable, CaseIterable, Sendable, Hashable {
    case simpleChain
    case reverseChain
    case longChain
    case doubleChain
    case parallelChains
    case interlockingChains
    case zigzagChain
    case brokenChain
    case alternatingDirectionChain
    case nestedChain

    case binaryBranch
    case tripleBranch
    case wideBranch
    case deepBranch
    case branchMerge
    case multipleBranches
    case asymmetricBranch
    case branchingTree

    case singleBottleneck
    case doubleBottleneck
    case centralBottleneck
    case edgeBottleneck
    case hiddenBottleneck
    case multiStageBottleneck

    case crossLock
    case doubleCross
    case horizontalVerticalLock
    case intersectionLock
    case crossBranch
    case crossBottleneck

    case dualCluster
    case tripleCluster
    case connectedClusters
    case isolatedClusters
    case clusterBridge
    case nestedClusters

    case bridgePattern
    case deepLock
    case multiBottleneck
    case dependencyWeb
    case convergingDependencies
    case divergingDependencies
    case multiStageUnlock
    case complexAsymmetric
    case expertHybrid
    case masterHybrid

    var family: PatternFamily {
        switch self {
        case .simpleChain, .reverseChain, .longChain, .doubleChain, .parallelChains,
             .interlockingChains, .zigzagChain, .brokenChain, .alternatingDirectionChain, .nestedChain:
            return .chain
        case .binaryBranch, .tripleBranch, .wideBranch, .deepBranch, .branchMerge,
             .multipleBranches, .asymmetricBranch, .branchingTree:
            return .branching
        case .singleBottleneck, .doubleBottleneck, .centralBottleneck, .edgeBottleneck,
             .hiddenBottleneck, .multiStageBottleneck:
            return .bottleneck
        case .crossLock, .doubleCross, .horizontalVerticalLock, .intersectionLock, .crossBranch, .crossBottleneck:
            return .cross
        case .dualCluster, .tripleCluster, .connectedClusters, .isolatedClusters, .clusterBridge, .nestedClusters:
            return .cluster
        case .bridgePattern, .deepLock, .multiBottleneck, .dependencyWeb, .convergingDependencies,
             .divergingDependencies, .multiStageUnlock, .complexAsymmetric:
            return .advanced
        case .expertHybrid, .masterHybrid:
            return .hybrid
        }
    }

    var displayName: String {
        switch self {
        case .simpleChain: "Simple Chain"
        case .reverseChain: "Reverse Chain"
        case .longChain: "Long Chain"
        case .doubleChain: "Double Chain"
        case .parallelChains: "Parallel Chains"
        case .interlockingChains: "Interlocking Chains"
        case .zigzagChain: "Zigzag Chain"
        case .brokenChain: "Broken Chain"
        case .alternatingDirectionChain: "Alternating Direction Chain"
        case .nestedChain: "Nested Chain"
        case .binaryBranch: "Binary Branch"
        case .tripleBranch: "Triple Branch"
        case .wideBranch: "Wide Branch"
        case .deepBranch: "Deep Branch"
        case .branchMerge: "Branch + Merge"
        case .multipleBranches: "Multiple Branches"
        case .asymmetricBranch: "Asymmetric Branch"
        case .branchingTree: "Branching Tree"
        case .singleBottleneck: "Single Bottleneck"
        case .doubleBottleneck: "Double Bottleneck"
        case .centralBottleneck: "Central Bottleneck"
        case .edgeBottleneck: "Edge Bottleneck"
        case .hiddenBottleneck: "Hidden Bottleneck"
        case .multiStageBottleneck: "Multi-stage Bottleneck"
        case .crossLock: "Cross Lock"
        case .doubleCross: "Double Cross"
        case .horizontalVerticalLock: "Horizontal/Vertical Lock"
        case .intersectionLock: "Intersection Lock"
        case .crossBranch: "Cross + Branch"
        case .crossBottleneck: "Cross + Bottleneck"
        case .dualCluster: "Dual Cluster"
        case .tripleCluster: "Triple Cluster"
        case .connectedClusters: "Connected Clusters"
        case .isolatedClusters: "Isolated-looking Clusters"
        case .clusterBridge: "Cluster + Bridge"
        case .nestedClusters: "Nested Clusters"
        case .bridgePattern: "Bridge Pattern"
        case .deepLock: "Deep Lock"
        case .multiBottleneck: "Multi-Bottleneck"
        case .dependencyWeb: "Dependency Web"
        case .convergingDependencies: "Converging Dependencies"
        case .divergingDependencies: "Diverging Dependencies"
        case .multiStageUnlock: "Multi-Stage Unlock"
        case .complexAsymmetric: "Complex Asymmetric"
        case .expertHybrid: "Expert Hybrid"
        case .masterHybrid: "Master Hybrid"
        }
    }

    var directionStrategy: DirectionStrategy {
        switch self {
        case .simpleChain, .reverseChain, .longChain: .aligned
        case .zigzagChain, .alternatingDirectionChain, .nestedChain: .alternating
        case .binaryBranch, .tripleBranch, .wideBranch, .centralBottleneck,
             .singleBottleneck, .edgeBottleneck, .divergingDependencies: .radial
        case .crossLock, .doubleCross, .horizontalVerticalLock, .intersectionLock,
             .crossBranch, .crossBottleneck: .intersecting
        default: .mixed
        }
    }
}

typealias LevelArchetype = PuzzlePattern

struct PatternBlueprint: Sendable {
    var pattern: PuzzlePattern
    var family: PatternFamily { pattern.family }
    var gridRange: ClosedRange<Int>
    var arrowRange: ClosedRange<Int>
    var depthRange: ClosedRange<Int>
    var branchingRange: ClosedRange<Int>
    var decoyBias: Double
    var clusterHint: Int
    var bottleneckHint: Int

    static func blueprint(for pattern: PuzzlePattern) -> PatternBlueprint {
        switch pattern {
        case .simpleChain:
            return PatternBlueprint(pattern: pattern, gridRange: 3...6, arrowRange: 3...8, depthRange: 2...7, branchingRange: 0...1, decoyBias: 0.05, clusterHint: 1, bottleneckHint: 0)
        case .reverseChain:
            return PatternBlueprint(pattern: pattern, gridRange: 3...6, arrowRange: 3...8, depthRange: 2...7, branchingRange: 0...1, decoyBias: 0.05, clusterHint: 1, bottleneckHint: 0)
        case .longChain:
            return PatternBlueprint(pattern: pattern, gridRange: 5...9, arrowRange: 8...16, depthRange: 6...14, branchingRange: 0...2, decoyBias: 0.04, clusterHint: 1, bottleneckHint: 0)
        case .doubleChain:
            return PatternBlueprint(pattern: pattern, gridRange: 5...8, arrowRange: 8...16, depthRange: 3...8, branchingRange: 0...2, decoyBias: 0.08, clusterHint: 2, bottleneckHint: 0)
        case .parallelChains:
            return PatternBlueprint(pattern: pattern, gridRange: 5...8, arrowRange: 8...16, depthRange: 3...8, branchingRange: 0...2, decoyBias: 0.1, clusterHint: 2, bottleneckHint: 0)
        case .interlockingChains:
            return PatternBlueprint(pattern: pattern, gridRange: 5...8, arrowRange: 9...18, depthRange: 4...10, branchingRange: 1...3, decoyBias: 0.08, clusterHint: 2, bottleneckHint: 1)
        case .zigzagChain:
            return PatternBlueprint(pattern: pattern, gridRange: 4...8, arrowRange: 6...14, depthRange: 4...10, branchingRange: 0...2, decoyBias: 0.06, clusterHint: 1, bottleneckHint: 0)
        case .brokenChain:
            return PatternBlueprint(pattern: pattern, gridRange: 4...7, arrowRange: 6...12, depthRange: 3...8, branchingRange: 0...2, decoyBias: 0.2, clusterHint: 1, bottleneckHint: 0)
        case .alternatingDirectionChain:
            return PatternBlueprint(pattern: pattern, gridRange: 4...8, arrowRange: 6...14, depthRange: 4...10, branchingRange: 0...2, decoyBias: 0.06, clusterHint: 1, bottleneckHint: 0)
        case .nestedChain:
            return PatternBlueprint(pattern: pattern, gridRange: 5...8, arrowRange: 8...16, depthRange: 4...10, branchingRange: 1...3, decoyBias: 0.08, clusterHint: 2, bottleneckHint: 1)
        case .binaryBranch:
            return PatternBlueprint(pattern: pattern, gridRange: 4...7, arrowRange: 5...12, depthRange: 2...6, branchingRange: 1...3, decoyBias: 0.1, clusterHint: 1, bottleneckHint: 1)
        case .tripleBranch:
            return PatternBlueprint(pattern: pattern, gridRange: 5...8, arrowRange: 7...14, depthRange: 2...6, branchingRange: 2...4, decoyBias: 0.1, clusterHint: 1, bottleneckHint: 1)
        case .wideBranch:
            return PatternBlueprint(pattern: pattern, gridRange: 6...9, arrowRange: 10...18, depthRange: 3...8, branchingRange: 2...5, decoyBias: 0.12, clusterHint: 1, bottleneckHint: 1)
        case .deepBranch:
            return PatternBlueprint(pattern: pattern, gridRange: 6...9, arrowRange: 10...20, depthRange: 5...12, branchingRange: 2...5, decoyBias: 0.08, clusterHint: 1, bottleneckHint: 1)
        case .branchMerge:
            return PatternBlueprint(pattern: pattern, gridRange: 5...8, arrowRange: 8...16, depthRange: 3...8, branchingRange: 1...3, decoyBias: 0.08, clusterHint: 1, bottleneckHint: 1)
        case .multipleBranches:
            return PatternBlueprint(pattern: pattern, gridRange: 6...9, arrowRange: 12...22, depthRange: 3...9, branchingRange: 2...6, decoyBias: 0.12, clusterHint: 2, bottleneckHint: 2)
        case .asymmetricBranch:
            return PatternBlueprint(pattern: pattern, gridRange: 5...8, arrowRange: 8...16, depthRange: 4...10, branchingRange: 1...3, decoyBias: 0.1, clusterHint: 1, bottleneckHint: 1)
        case .branchingTree:
            return PatternBlueprint(pattern: pattern, gridRange: 5...8, arrowRange: 8...18, depthRange: 3...9, branchingRange: 2...5, decoyBias: 0.1, clusterHint: 1, bottleneckHint: 1)
        case .singleBottleneck:
            return PatternBlueprint(pattern: pattern, gridRange: 4...7, arrowRange: 6...12, depthRange: 2...6, branchingRange: 2...4, decoyBias: 0.05, clusterHint: 1, bottleneckHint: 1)
        case .doubleBottleneck:
            return PatternBlueprint(pattern: pattern, gridRange: 5...8, arrowRange: 8...16, depthRange: 4...9, branchingRange: 2...4, decoyBias: 0.06, clusterHint: 1, bottleneckHint: 2)
        case .centralBottleneck:
            return PatternBlueprint(pattern: pattern, gridRange: 5...8, arrowRange: 7...14, depthRange: 2...6, branchingRange: 2...4, decoyBias: 0.05, clusterHint: 1, bottleneckHint: 1)
        case .edgeBottleneck:
            return PatternBlueprint(pattern: pattern, gridRange: 5...8, arrowRange: 7...14, depthRange: 2...6, branchingRange: 2...4, decoyBias: 0.05, clusterHint: 1, bottleneckHint: 1)
        case .hiddenBottleneck:
            return PatternBlueprint(pattern: pattern, gridRange: 5...8, arrowRange: 8...16, depthRange: 3...8, branchingRange: 2...4, decoyBias: 0.22, clusterHint: 1, bottleneckHint: 1)
        case .multiStageBottleneck:
            return PatternBlueprint(pattern: pattern, gridRange: 6...9, arrowRange: 10...20, depthRange: 5...12, branchingRange: 2...5, decoyBias: 0.08, clusterHint: 1, bottleneckHint: 2)
        case .crossLock:
            return PatternBlueprint(pattern: pattern, gridRange: 5...8, arrowRange: 8...16, depthRange: 3...8, branchingRange: 1...3, decoyBias: 0.08, clusterHint: 1, bottleneckHint: 1)
        case .doubleCross:
            return PatternBlueprint(pattern: pattern, gridRange: 6...9, arrowRange: 12...22, depthRange: 4...10, branchingRange: 2...5, decoyBias: 0.1, clusterHint: 1, bottleneckHint: 2)
        case .horizontalVerticalLock:
            return PatternBlueprint(pattern: pattern, gridRange: 5...8, arrowRange: 8...16, depthRange: 3...8, branchingRange: 1...3, decoyBias: 0.08, clusterHint: 1, bottleneckHint: 1)
        case .intersectionLock:
            return PatternBlueprint(pattern: pattern, gridRange: 5...8, arrowRange: 9...18, depthRange: 4...10, branchingRange: 1...4, decoyBias: 0.08, clusterHint: 1, bottleneckHint: 1)
        case .crossBranch:
            return PatternBlueprint(pattern: pattern, gridRange: 6...9, arrowRange: 10...20, depthRange: 4...10, branchingRange: 2...5, decoyBias: 0.1, clusterHint: 1, bottleneckHint: 1)
        case .crossBottleneck:
            return PatternBlueprint(pattern: pattern, gridRange: 6...9, arrowRange: 10...20, depthRange: 4...10, branchingRange: 2...5, decoyBias: 0.08, clusterHint: 1, bottleneckHint: 2)
        case .dualCluster:
            return PatternBlueprint(pattern: pattern, gridRange: 6...9, arrowRange: 10...18, depthRange: 3...8, branchingRange: 0...3, decoyBias: 0.1, clusterHint: 2, bottleneckHint: 0)
        case .tripleCluster:
            return PatternBlueprint(pattern: pattern, gridRange: 7...10, arrowRange: 12...24, depthRange: 3...9, branchingRange: 1...4, decoyBias: 0.12, clusterHint: 3, bottleneckHint: 0)
        case .connectedClusters:
            return PatternBlueprint(pattern: pattern, gridRange: 6...9, arrowRange: 12...22, depthRange: 4...10, branchingRange: 1...4, decoyBias: 0.1, clusterHint: 2, bottleneckHint: 1)
        case .isolatedClusters:
            return PatternBlueprint(pattern: pattern, gridRange: 6...9, arrowRange: 10...20, depthRange: 3...8, branchingRange: 0...3, decoyBias: 0.14, clusterHint: 2, bottleneckHint: 0)
        case .clusterBridge:
            return PatternBlueprint(pattern: pattern, gridRange: 6...9, arrowRange: 10...20, depthRange: 4...10, branchingRange: 1...4, decoyBias: 0.08, clusterHint: 2, bottleneckHint: 1)
        case .nestedClusters:
            return PatternBlueprint(pattern: pattern, gridRange: 6...9, arrowRange: 12...22, depthRange: 4...11, branchingRange: 1...4, decoyBias: 0.1, clusterHint: 2, bottleneckHint: 1)
        case .bridgePattern:
            return PatternBlueprint(pattern: pattern, gridRange: 6...9, arrowRange: 10...20, depthRange: 4...10, branchingRange: 1...4, decoyBias: 0.08, clusterHint: 2, bottleneckHint: 1)
        case .deepLock:
            return PatternBlueprint(pattern: pattern, gridRange: 6...9, arrowRange: 10...20, depthRange: 7...16, branchingRange: 1...3, decoyBias: 0.04, clusterHint: 1, bottleneckHint: 1)
        case .multiBottleneck:
            return PatternBlueprint(pattern: pattern, gridRange: 6...9, arrowRange: 12...24, depthRange: 5...12, branchingRange: 2...6, decoyBias: 0.08, clusterHint: 1, bottleneckHint: 3)
        case .dependencyWeb:
            return PatternBlueprint(pattern: pattern, gridRange: 6...10, arrowRange: 14...28, depthRange: 6...14, branchingRange: 3...7, decoyBias: 0.1, clusterHint: 1, bottleneckHint: 2)
        case .convergingDependencies:
            return PatternBlueprint(pattern: pattern, gridRange: 5...8, arrowRange: 8...16, depthRange: 3...8, branchingRange: 1...3, decoyBias: 0.08, clusterHint: 1, bottleneckHint: 1)
        case .divergingDependencies:
            return PatternBlueprint(pattern: pattern, gridRange: 5...8, arrowRange: 8...16, depthRange: 3...8, branchingRange: 2...5, decoyBias: 0.1, clusterHint: 1, bottleneckHint: 1)
        case .multiStageUnlock:
            return PatternBlueprint(pattern: pattern, gridRange: 6...9, arrowRange: 12...24, depthRange: 6...14, branchingRange: 2...5, decoyBias: 0.08, clusterHint: 1, bottleneckHint: 2)
        case .complexAsymmetric:
            return PatternBlueprint(pattern: pattern, gridRange: 6...10, arrowRange: 12...26, depthRange: 6...14, branchingRange: 2...6, decoyBias: 0.12, clusterHint: 2, bottleneckHint: 1)
        case .expertHybrid:
            return PatternBlueprint(pattern: pattern, gridRange: 7...10, arrowRange: 16...30, depthRange: 8...16, branchingRange: 2...6, decoyBias: 0.12, clusterHint: 2, bottleneckHint: 2)
        case .masterHybrid:
            return PatternBlueprint(pattern: pattern, gridRange: 8...10, arrowRange: 18...36, depthRange: 10...20, branchingRange: 3...8, decoyBias: 0.14, clusterHint: 3, bottleneckHint: 3)
        }
    }
}
