import SpriteKit
import UIKit

enum BoardPalette {
    static var background: SKColor { named("BackgroundColor", fallback: SKColor(red: 0.96, green: 0.94, blue: 0.90, alpha: 1)) }
    static var board: SKColor { named("BoardColor", fallback: SKColor(red: 1, green: 0.99, blue: 0.97, alpha: 1)) }
    static var grid: SKColor { named("DividerColor", fallback: SKColor(red: 0.86, green: 0.83, blue: 0.78, alpha: 1)) }
    static var primary: SKColor { named("BrandPrimary", fallback: SKColor(red: 0.16, green: 0.42, blue: 0.42, alpha: 1)) }
    static var secondary: SKColor { named("BrandSecondary", fallback: SKColor(red: 0.76, green: 0.42, blue: 0.32, alpha: 1)) }
    static var accent: SKColor { named("AccentColor", fallback: SKColor(red: 0.86, green: 0.62, blue: 0.18, alpha: 1)) }
    static var success: SKColor { named("SuccessColor", fallback: SKColor(red: 0.29, green: 0.58, blue: 0.42, alpha: 1)) }
    static var arrow: SKColor { SKColor(red: 0.22, green: 0.47, blue: 0.73, alpha: 1) }
    static var dot: SKColor { SKColor(white: 0.82, alpha: 1) }

    static func fill(for _: Direction) -> SKColor {
        arrow
    }

    private static func named(_ name: String, fallback: SKColor) -> SKColor {
        SKColor(named: name) ?? fallback
    }
}
