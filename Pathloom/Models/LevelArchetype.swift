import Foundation

enum LevelArchetype: String, Codable, CaseIterable, Sendable, Hashable {
    case simpleChain
    case reverseChain
    case branchingTree
    case bottleneck
    case doubleBottleneck
    case crossDependency
    case chainReaction
    case multiCluster
    case bridge
    case zigZag
    case spiralLike
    case cornerTrap
    case denseCenter
    case denseEdge
    case splitBoard
    case convergingDependencies
    case divergingDependencies
    case mixedDirection
    case singleMoveStart
    case multipleMoveStart
    case deepLock
    case asymmetricMaze
    case doubleCluster
    case tripleCluster
    case longDependency
    case shortDependencyHighBranching
    case highDensityLowDepth
    case lowDensityHighDepth
    case mixedComplexity
    case expertChallenge

    var displayName: String {
        switch self {
        case .simpleChain: "Simple Chain"
        case .reverseChain: "Reverse Chain"
        case .branchingTree: "Branching Tree"
        case .bottleneck: "Bottleneck"
        case .doubleBottleneck: "Double Bottleneck"
        case .crossDependency: "Cross Dependency"
        case .chainReaction: "Chain Reaction"
        case .multiCluster: "Multi Cluster"
        case .bridge: "Bridge"
        case .zigZag: "Zig-Zag"
        case .spiralLike: "Spiral-like"
        case .cornerTrap: "Corner Trap"
        case .denseCenter: "Dense Center"
        case .denseEdge: "Dense Edge"
        case .splitBoard: "Split Board"
        case .convergingDependencies: "Converging Dependencies"
        case .divergingDependencies: "Diverging Dependencies"
        case .mixedDirection: "Mixed Direction"
        case .singleMoveStart: "Single-Move Start"
        case .multipleMoveStart: "Multiple-Move Start"
        case .deepLock: "Deep Lock"
        case .asymmetricMaze: "Asymmetric Maze"
        case .doubleCluster: "Double Cluster"
        case .tripleCluster: "Triple Cluster"
        case .longDependency: "Long Dependency"
        case .shortDependencyHighBranching: "Short Dependency / High Branching"
        case .highDensityLowDepth: "High Density / Low Depth"
        case .lowDensityHighDepth: "Low Density / High Depth"
        case .mixedComplexity: "Mixed Complexity"
        case .expertChallenge: "Expert Challenge"
        }
    }
}
