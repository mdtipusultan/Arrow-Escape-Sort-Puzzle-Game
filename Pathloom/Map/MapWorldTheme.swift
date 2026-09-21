import SwiftUI

struct MapRGB: Equatable, Sendable {
    var r: Double
    var g: Double
    var b: Double

    var color: Color { Color(red: r, green: g, blue: b) }

    func mixed(with other: MapRGB, t: Double) -> MapRGB {
        let u = min(max(t, 0), 1)
        return MapRGB(
            r: r + (other.r - r) * u,
            g: g + (other.g - g) * u,
            b: b + (other.b - b) * u
        )
    }
}

struct MapWorldTheme: Equatable, Sendable {
    let accent: MapRGB
    let secondary: MapRGB
    let skyTop: MapRGB
    let skyBottom: MapRGB
    let atmosphere: MapRGB
    let pathLit: MapRGB
    let pathDim: MapRGB
    let terrainFar: MapRGB
    let terrainMid: MapRGB
    let terrainNear: MapRGB
    let sparkle: MapRGB
    let nodeFill: MapRGB
    let nodeGlow: MapRGB
    let fog: MapRGB

    func mixed(with other: MapWorldTheme, t: Double) -> MapWorldTheme {
        MapWorldTheme(
            accent: accent.mixed(with: other.accent, t: t),
            secondary: secondary.mixed(with: other.secondary, t: t),
            skyTop: skyTop.mixed(with: other.skyTop, t: t),
            skyBottom: skyBottom.mixed(with: other.skyBottom, t: t),
            atmosphere: atmosphere.mixed(with: other.atmosphere, t: t),
            pathLit: pathLit.mixed(with: other.pathLit, t: t),
            pathDim: pathDim.mixed(with: other.pathDim, t: t),
            terrainFar: terrainFar.mixed(with: other.terrainFar, t: t),
            terrainMid: terrainMid.mixed(with: other.terrainMid, t: t),
            terrainNear: terrainNear.mixed(with: other.terrainNear, t: t),
            sparkle: sparkle.mixed(with: other.sparkle, t: t),
            nodeFill: nodeFill.mixed(with: other.nodeFill, t: t),
            nodeGlow: nodeGlow.mixed(with: other.nodeGlow, t: t),
            fog: fog.mixed(with: other.fog, t: t)
        )
    }

    static func theme(for sectionIndex: Int) -> MapWorldTheme {
        let themes = palette
        if sectionIndex >= 0, sectionIndex < themes.count {
            return themes[sectionIndex]
        }
        return themes[themes.count - 1]
    }

    static func theme(atY y: CGFloat, layout: MapLayout) -> MapWorldTheme {
        let sections = layout.sections
        guard let first = sections.first else { return theme(for: 0) }
        if y >= first.yBottom { return theme(for: first.index) }
        if let last = sections.last, y <= last.yTop { return theme(for: last.index) }

        for (index, section) in sections.enumerated() {
            if y <= section.yBottom && y >= section.yTop {
                let span = max(section.yBottom - section.yTop, 1)
                let t = Double((section.yBottom - y) / span)
                let blendStart = 0.72
                if t > blendStart, index + 1 < sections.count {
                    let local = (t - blendStart) / (1 - blendStart)
                    return theme(for: section.index).mixed(with: theme(for: sections[index + 1].index), t: local)
                }
                return theme(for: section.index)
            }
            if index + 1 < sections.count {
                let next = sections[index + 1]
                if y < section.yTop && y > next.yBottom {
                    let span = max(section.yTop - next.yBottom, 1)
                    let t = Double((section.yTop - y) / span)
                    return theme(for: section.index).mixed(with: theme(for: next.index), t: t)
                }
            }
        }
        return theme(for: first.index)
    }

    private static let palette: [MapWorldTheme] = [
        // 0 Sunthread Meadows
        MapWorldTheme(
            accent: MapRGB(r: 0.40, g: 0.62, b: 0.36),
            secondary: MapRGB(r: 0.90, g: 0.74, b: 0.38),
            skyTop: MapRGB(r: 0.97, g: 0.93, b: 0.80),
            skyBottom: MapRGB(r: 0.86, g: 0.90, b: 0.72),
            atmosphere: MapRGB(r: 0.95, g: 0.91, b: 0.76),
            pathLit: MapRGB(r: 0.78, g: 0.62, b: 0.30),
            pathDim: MapRGB(r: 0.62, g: 0.68, b: 0.52),
            terrainFar: MapRGB(r: 0.72, g: 0.80, b: 0.58),
            terrainMid: MapRGB(r: 0.56, g: 0.70, b: 0.44),
            terrainNear: MapRGB(r: 0.48, g: 0.64, b: 0.38),
            sparkle: MapRGB(r: 0.98, g: 0.90, b: 0.55),
            nodeFill: MapRGB(r: 0.97, g: 0.97, b: 0.90),
            nodeGlow: MapRGB(r: 0.48, g: 0.72, b: 0.40),
            fog: MapRGB(r: 0.98, g: 0.96, b: 0.88)
        ),
        // 1 Verdant Loomwood
        MapWorldTheme(
            accent: MapRGB(r: 0.22, g: 0.52, b: 0.44),
            secondary: MapRGB(r: 0.46, g: 0.72, b: 0.58),
            skyTop: MapRGB(r: 0.78, g: 0.88, b: 0.82),
            skyBottom: MapRGB(r: 0.58, g: 0.74, b: 0.66),
            atmosphere: MapRGB(r: 0.80, g: 0.88, b: 0.82),
            pathLit: MapRGB(r: 0.30, g: 0.58, b: 0.48),
            pathDim: MapRGB(r: 0.50, g: 0.62, b: 0.54),
            terrainFar: MapRGB(r: 0.38, g: 0.56, b: 0.48),
            terrainMid: MapRGB(r: 0.26, g: 0.48, b: 0.40),
            terrainNear: MapRGB(r: 0.20, g: 0.40, b: 0.34),
            sparkle: MapRGB(r: 0.82, g: 0.95, b: 0.78),
            nodeFill: MapRGB(r: 0.90, g: 0.96, b: 0.92),
            nodeGlow: MapRGB(r: 0.34, g: 0.70, b: 0.56),
            fog: MapRGB(r: 0.86, g: 0.92, b: 0.88)
        ),
        // 2 Glassbrook Vale
        MapWorldTheme(
            accent: MapRGB(r: 0.28, g: 0.58, b: 0.72),
            secondary: MapRGB(r: 0.62, g: 0.52, b: 0.84),
            skyTop: MapRGB(r: 0.80, g: 0.90, b: 0.96),
            skyBottom: MapRGB(r: 0.70, g: 0.82, b: 0.92),
            atmosphere: MapRGB(r: 0.82, g: 0.90, b: 0.95),
            pathLit: MapRGB(r: 0.36, g: 0.70, b: 0.82),
            pathDim: MapRGB(r: 0.58, g: 0.70, b: 0.78),
            terrainFar: MapRGB(r: 0.52, g: 0.70, b: 0.82),
            terrainMid: MapRGB(r: 0.42, g: 0.62, b: 0.76),
            terrainNear: MapRGB(r: 0.34, g: 0.54, b: 0.70),
            sparkle: MapRGB(r: 0.88, g: 0.96, b: 1.0),
            nodeFill: MapRGB(r: 0.92, g: 0.97, b: 0.99),
            nodeGlow: MapRGB(r: 0.48, g: 0.78, b: 0.90),
            fog: MapRGB(r: 0.90, g: 0.95, b: 0.98)
        ),
        // 3 Nimbus Gallery
        MapWorldTheme(
            accent: MapRGB(r: 0.42, g: 0.62, b: 0.82),
            secondary: MapRGB(r: 0.96, g: 0.84, b: 0.72),
            skyTop: MapRGB(r: 0.90, g: 0.94, b: 0.98),
            skyBottom: MapRGB(r: 0.78, g: 0.86, b: 0.94),
            atmosphere: MapRGB(r: 0.88, g: 0.92, b: 0.96),
            pathLit: MapRGB(r: 0.50, g: 0.68, b: 0.86),
            pathDim: MapRGB(r: 0.64, g: 0.72, b: 0.80),
            terrainFar: MapRGB(r: 0.70, g: 0.80, b: 0.90),
            terrainMid: MapRGB(r: 0.62, g: 0.74, b: 0.86),
            terrainNear: MapRGB(r: 0.54, g: 0.68, b: 0.82),
            sparkle: MapRGB(r: 1.0, g: 1.0, b: 1.0),
            nodeFill: MapRGB(r: 0.96, g: 0.98, b: 1.0),
            nodeGlow: MapRGB(r: 0.56, g: 0.74, b: 0.92),
            fog: MapRGB(r: 0.96, g: 0.97, b: 0.99)
        ),
        // 4 Violet Range
        MapWorldTheme(
            accent: MapRGB(r: 0.46, g: 0.36, b: 0.70),
            secondary: MapRGB(r: 0.90, g: 0.58, b: 0.42),
            skyTop: MapRGB(r: 0.62, g: 0.52, b: 0.78),
            skyBottom: MapRGB(r: 0.42, g: 0.36, b: 0.58),
            atmosphere: MapRGB(r: 0.70, g: 0.64, b: 0.82),
            pathLit: MapRGB(r: 0.78, g: 0.58, b: 0.42),
            pathDim: MapRGB(r: 0.56, g: 0.50, b: 0.66),
            terrainFar: MapRGB(r: 0.44, g: 0.38, b: 0.60),
            terrainMid: MapRGB(r: 0.36, g: 0.30, b: 0.50),
            terrainNear: MapRGB(r: 0.30, g: 0.24, b: 0.42),
            sparkle: MapRGB(r: 0.98, g: 0.82, b: 0.58),
            nodeFill: MapRGB(r: 0.94, g: 0.90, b: 0.98),
            nodeGlow: MapRGB(r: 0.72, g: 0.52, b: 0.88),
            fog: MapRGB(r: 0.58, g: 0.50, b: 0.70)
        ),
        // 5 Oldweave Ruins
        MapWorldTheme(
            accent: MapRGB(r: 0.68, g: 0.48, b: 0.34),
            secondary: MapRGB(r: 0.46, g: 0.58, b: 0.40),
            skyTop: MapRGB(r: 0.90, g: 0.82, b: 0.70),
            skyBottom: MapRGB(r: 0.76, g: 0.66, b: 0.52),
            atmosphere: MapRGB(r: 0.88, g: 0.80, b: 0.68),
            pathLit: MapRGB(r: 0.72, g: 0.52, b: 0.34),
            pathDim: MapRGB(r: 0.66, g: 0.60, b: 0.50),
            terrainFar: MapRGB(r: 0.70, g: 0.58, b: 0.44),
            terrainMid: MapRGB(r: 0.60, g: 0.48, b: 0.36),
            terrainNear: MapRGB(r: 0.52, g: 0.40, b: 0.30),
            sparkle: MapRGB(r: 0.94, g: 0.82, b: 0.52),
            nodeFill: MapRGB(r: 0.96, g: 0.92, b: 0.84),
            nodeGlow: MapRGB(r: 0.80, g: 0.58, b: 0.36),
            fog: MapRGB(r: 0.90, g: 0.84, b: 0.72)
        ),
        // 6 Nightloom Expanse
        MapWorldTheme(
            accent: MapRGB(r: 0.34, g: 0.42, b: 0.78),
            secondary: MapRGB(r: 0.88, g: 0.74, b: 0.42),
            skyTop: MapRGB(r: 0.18, g: 0.20, b: 0.38),
            skyBottom: MapRGB(r: 0.10, g: 0.12, b: 0.24),
            atmosphere: MapRGB(r: 0.22, g: 0.24, b: 0.40),
            pathLit: MapRGB(r: 0.86, g: 0.72, b: 0.40),
            pathDim: MapRGB(r: 0.40, g: 0.44, b: 0.60),
            terrainFar: MapRGB(r: 0.20, g: 0.22, b: 0.40),
            terrainMid: MapRGB(r: 0.16, g: 0.18, b: 0.34),
            terrainNear: MapRGB(r: 0.12, g: 0.14, b: 0.28),
            sparkle: MapRGB(r: 0.96, g: 0.90, b: 0.62),
            nodeFill: MapRGB(r: 0.88, g: 0.90, b: 0.98),
            nodeGlow: MapRGB(r: 0.90, g: 0.76, b: 0.42),
            fog: MapRGB(r: 0.16, g: 0.18, b: 0.32)
        ),
        // 7 Aurora Spire
        MapWorldTheme(
            accent: MapRGB(r: 0.28, g: 0.72, b: 0.68),
            secondary: MapRGB(r: 0.82, g: 0.46, b: 0.78),
            skyTop: MapRGB(r: 0.16, g: 0.28, b: 0.42),
            skyBottom: MapRGB(r: 0.10, g: 0.16, b: 0.30),
            atmosphere: MapRGB(r: 0.20, g: 0.32, b: 0.44),
            pathLit: MapRGB(r: 0.46, g: 0.86, b: 0.78),
            pathDim: MapRGB(r: 0.42, g: 0.50, b: 0.64),
            terrainFar: MapRGB(r: 0.22, g: 0.36, b: 0.46),
            terrainMid: MapRGB(r: 0.18, g: 0.30, b: 0.40),
            terrainNear: MapRGB(r: 0.14, g: 0.24, b: 0.34),
            sparkle: MapRGB(r: 0.78, g: 0.96, b: 0.90),
            nodeFill: MapRGB(r: 0.90, g: 0.96, b: 0.96),
            nodeGlow: MapRGB(r: 0.52, g: 0.86, b: 0.80),
            fog: MapRGB(r: 0.18, g: 0.28, b: 0.40)
        )
    ]
}
