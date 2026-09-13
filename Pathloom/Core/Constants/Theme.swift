import SwiftUI

enum PathloomPalette {
    static let background = Color("BackgroundColor")
    static let board = Color("BoardColor")
    static let primary = Color("BrandPrimary")
    static let secondary = Color("BrandSecondary")
    static let accent = Color("AccentColor")
    static let success = Color("SuccessColor")
    static let warning = Color("WarningColor")
    static let text = Color("TextColor")
    static let mutedText = Color("MutedTextColor")
    static let card = Color("CardColor")
    static let divider = Color("DividerColor")
    static let arrow = Color(red: 0.22, green: 0.47, blue: 0.73)

    static func arrowFill(for _: Direction) -> Color {
        arrow
    }
}

enum PathloomRadius {
    static let small: CGFloat = 10
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
    static let extraLarge: CGFloat = 32
}

enum PathloomSpacing {
    static let xs: CGFloat = 6
    static let sm: CGFloat = 10
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}
