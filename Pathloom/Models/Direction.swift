import Foundation

enum Direction: String, Codable, CaseIterable, Sendable, Hashable {
    case up
    case down
    case left
    case right

    var rowDelta: Int {
        switch self {
        case .up: -1
        case .down: 1
        case .left, .right: 0
        }
    }

    var columnDelta: Int {
        switch self {
        case .left: -1
        case .right: 1
        case .up, .down: 0
        }
    }

    var accessibilityName: String {
        rawValue
    }

    var rotationRadians: CGFloat {
        switch self {
        case .up: 0
        case .right: .pi / 2
        case .down: .pi
        case .left: .pi * 1.5
        }
    }
}
