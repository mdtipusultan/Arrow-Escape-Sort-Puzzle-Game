import Foundation

enum GameState: String, Sendable, Equatable {
    case ready
    case playing
    case paused
    case completing
    case completed
}

enum EscapeOutcome: Equatable, Sendable {
    case blocked
    case escaped(pathLength: Int)
}

enum GameEngineError: Error, Equatable {
    case unknownArrow
    case inactiveArrow
    case invalidState
}
