import SwiftUI

struct MapWorldTheme: Equatable {
    let accent: Color
    let secondary: Color
    let atmosphere: Color
    let pathLit: Color
    let pathDim: Color
    let terrain: Color
    let sparkle: Color
    let nodeFill: Color
    let nodeGlow: Color

    static func theme(for sectionIndex: Int) -> MapWorldTheme {
        switch sectionIndex {
        case 0:
            return MapWorldTheme(
                accent: Color(red: 0.42, green: 0.62, blue: 0.38),
                secondary: Color(red: 0.86, green: 0.72, blue: 0.38),
                atmosphere: Color(red: 0.93, green: 0.89, blue: 0.76),
                pathLit: Color(red: 0.36, green: 0.58, blue: 0.42),
                pathDim: Color(red: 0.62, green: 0.68, blue: 0.55),
                terrain: Color(red: 0.55, green: 0.70, blue: 0.48),
                sparkle: Color(red: 0.95, green: 0.88, blue: 0.55),
                nodeFill: Color(red: 0.93, green: 0.96, blue: 0.88),
                nodeGlow: Color(red: 0.45, green: 0.70, blue: 0.42)
            )
        case 1:
            return MapWorldTheme(
                accent: Color(red: 0.28, green: 0.62, blue: 0.68),
                secondary: Color(red: 0.55, green: 0.78, blue: 0.82),
                atmosphere: Color(red: 0.82, green: 0.91, blue: 0.92),
                pathLit: Color(red: 0.18, green: 0.55, blue: 0.60),
                pathDim: Color(red: 0.58, green: 0.70, blue: 0.72),
                terrain: Color(red: 0.40, green: 0.68, blue: 0.70),
                sparkle: Color.white,
                nodeFill: Color(red: 0.90, green: 0.97, blue: 0.97),
                nodeGlow: Color(red: 0.32, green: 0.72, blue: 0.76)
            )
        case 2:
            return MapWorldTheme(
                accent: Color(red: 0.48, green: 0.38, blue: 0.66),
                secondary: Color(red: 0.72, green: 0.52, blue: 0.78),
                atmosphere: Color(red: 0.86, green: 0.82, blue: 0.92),
                pathLit: Color(red: 0.46, green: 0.36, blue: 0.64),
                pathDim: Color(red: 0.66, green: 0.62, blue: 0.74),
                terrain: Color(red: 0.52, green: 0.44, blue: 0.68),
                sparkle: Color(red: 0.90, green: 0.78, blue: 0.96),
                nodeFill: Color(red: 0.94, green: 0.90, blue: 0.98),
                nodeGlow: Color(red: 0.62, green: 0.48, blue: 0.82)
            )
        case 3:
            return MapWorldTheme(
                accent: Color(red: 0.78, green: 0.42, blue: 0.28),
                secondary: Color(red: 0.90, green: 0.62, blue: 0.32),
                atmosphere: Color(red: 0.94, green: 0.86, blue: 0.76),
                pathLit: Color(red: 0.74, green: 0.40, blue: 0.26),
                pathDim: Color(red: 0.76, green: 0.64, blue: 0.54),
                terrain: Color(red: 0.72, green: 0.48, blue: 0.34),
                sparkle: Color(red: 0.98, green: 0.82, blue: 0.48),
                nodeFill: Color(red: 0.98, green: 0.93, blue: 0.86),
                nodeGlow: Color(red: 0.88, green: 0.52, blue: 0.30)
            )
        case 4:
            return MapWorldTheme(
                accent: Color(red: 0.32, green: 0.36, blue: 0.64),
                secondary: Color(red: 0.52, green: 0.58, blue: 0.86),
                atmosphere: Color(red: 0.76, green: 0.78, blue: 0.90),
                pathLit: Color(red: 0.30, green: 0.34, blue: 0.62),
                pathDim: Color(red: 0.56, green: 0.58, blue: 0.70),
                terrain: Color(red: 0.38, green: 0.40, blue: 0.60),
                sparkle: Color(red: 0.82, green: 0.88, blue: 1.0),
                nodeFill: Color(red: 0.90, green: 0.91, blue: 0.98),
                nodeGlow: Color(red: 0.50, green: 0.56, blue: 0.90)
            )
        case 5:
            return MapWorldTheme(
                accent: Color(red: 0.22, green: 0.66, blue: 0.58),
                secondary: Color(red: 0.58, green: 0.48, blue: 0.82),
                atmosphere: Color(red: 0.78, green: 0.90, blue: 0.88),
                pathLit: Color(red: 0.18, green: 0.60, blue: 0.56),
                pathDim: Color(red: 0.54, green: 0.68, blue: 0.70),
                terrain: Color(red: 0.30, green: 0.62, blue: 0.60),
                sparkle: Color(red: 0.72, green: 0.95, blue: 0.86),
                nodeFill: Color(red: 0.88, green: 0.97, blue: 0.94),
                nodeGlow: Color(red: 0.36, green: 0.78, blue: 0.70)
            )
        case 6:
            return MapWorldTheme(
                accent: Color(red: 0.36, green: 0.58, blue: 0.78),
                secondary: Color(red: 0.70, green: 0.84, blue: 0.92),
                atmosphere: Color(red: 0.80, green: 0.88, blue: 0.94),
                pathLit: Color(red: 0.28, green: 0.52, blue: 0.74),
                pathDim: Color(red: 0.58, green: 0.68, blue: 0.76),
                terrain: Color(red: 0.42, green: 0.62, blue: 0.76),
                sparkle: Color(red: 0.85, green: 0.95, blue: 1.0),
                nodeFill: Color(red: 0.90, green: 0.95, blue: 0.99),
                nodeGlow: Color(red: 0.42, green: 0.70, blue: 0.88)
            )
        case 7:
            return MapWorldTheme(
                accent: Color(red: 0.18, green: 0.24, blue: 0.46),
                secondary: Color(red: 0.78, green: 0.66, blue: 0.36),
                atmosphere: Color(red: 0.22, green: 0.24, blue: 0.38),
                pathLit: Color(red: 0.82, green: 0.70, blue: 0.38),
                pathDim: Color(red: 0.42, green: 0.44, blue: 0.58),
                terrain: Color(red: 0.26, green: 0.30, blue: 0.50),
                sparkle: Color(red: 0.96, green: 0.88, blue: 0.58),
                nodeFill: Color(red: 0.86, green: 0.88, blue: 0.96),
                nodeGlow: Color(red: 0.90, green: 0.74, blue: 0.40)
            )
        default:
            return MapWorldTheme(
                accent: Color(red: 0.20, green: 0.48, blue: 0.50),
                secondary: Color(red: 0.88, green: 0.76, blue: 0.42),
                atmosphere: Color(red: 0.90, green: 0.86, blue: 0.74),
                pathLit: Color(red: 0.18, green: 0.50, blue: 0.52),
                pathDim: Color(red: 0.62, green: 0.66, blue: 0.58),
                terrain: Color(red: 0.36, green: 0.56, blue: 0.54),
                sparkle: Color(red: 0.98, green: 0.90, blue: 0.62),
                nodeFill: Color(red: 0.95, green: 0.94, blue: 0.88),
                nodeGlow: Color(red: 0.32, green: 0.64, blue: 0.62)
            )
        }
    }
}
