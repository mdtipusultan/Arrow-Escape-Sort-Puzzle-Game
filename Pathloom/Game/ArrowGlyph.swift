import SpriteKit
import SwiftUI
import UIKit

enum PuzzleArrowStyle: Hashable, Sendable {
    case straight
    case turnRight
    case turnLeft
    case diagonal

    var systemName: String {
        switch self {
        case .straight: "arrow.up"
        case .turnRight: "arrow.turn.up.right"
        case .turnLeft: "arrow.turn.up.left"
        case .diagonal: "arrow.up.left"
        }
    }
}

enum ArrowGlyph {
    static func image(
        size: CGFloat,
        color: UIColor,
        style: PuzzleArrowStyle = .straight
    ) -> UIImage {
        let pointSize = max(size * 0.62, 12)
        let configuration = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .semibold)
        let symbol = UIImage(systemName: style.systemName, withConfiguration: configuration)
            ?? UIImage(systemName: "arrow.up", withConfiguration: configuration)
            ?? UIImage()
        return symbol.withTintColor(color, renderingMode: .alwaysOriginal)
    }

    /// SpriteKit rotates counterclockwise; `Direction.rotationRadians` is clockwise (SwiftUI).
    static func spriteRotation(for direction: Direction) -> CGFloat {
        -direction.rotationRadians
    }
}

struct PuzzleArrowView: View {
    var direction: Direction
    var style: PuzzleArrowStyle = .straight
    var size: CGFloat = 36
    var color: Color = PathloomPalette.arrow

    var body: some View {
        Image(systemName: style.systemName)
            .font(.system(size: size, weight: .semibold))
            .foregroundStyle(color)
            .rotationEffect(.radians(Double(direction.rotationRadians)))
            .frame(width: size * 1.6, height: size * 1.6)
    }
}
