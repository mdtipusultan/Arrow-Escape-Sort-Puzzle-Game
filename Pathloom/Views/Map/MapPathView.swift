import SwiftUI

struct MapPathView: View {
    let layout: MapLayout
    let unlockedThrough: Int
    let revealLevelID: Int?

    var body: some View {
        Canvas { context, _ in
            let points = layout.pathPoints
            guard points.count >= 2 else { return }

            let unlockedIndex = min(max(unlockedThrough, 0), layout.nodes.count)
            let split = 1 + unlockedIndex

            if split >= 2 {
                strokeSegments(Array(points.prefix(split + 1)), in: &context, lit: true)
            }

            if split < points.count {
                let dimPoints = Array(points.suffix(from: max(split - 1, 0)))
                strokeSegments(dimPoints, in: &context, lit: false)
            }

            if let reveal = revealLevelID, let node = layout.node(for: reveal) {
                let glow = Path(ellipseIn: CGRect(
                    x: node.position.x - node.radius - 12,
                    y: node.position.y - node.radius - 12,
                    width: (node.radius + 12) * 2,
                    height: (node.radius + 12) * 2
                ))
                let theme = MapWorldTheme.theme(for: node.sectionIndex)
                context.fill(glow, with: .color(theme.nodeGlow.color.opacity(0.18)))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func strokeSegments(_ points: [CGPoint], in context: inout GraphicsContext, lit: Bool) {
        let path = curve(through: points)
        guard !path.isEmpty else { return }

        let midTheme = theme(forPoints: points)
        let glow = lit ? midTheme.nodeGlow.color.opacity(0.20) : Color.black.opacity(0.04)
        context.stroke(path, with: .color(glow), style: StrokeStyle(lineWidth: 18, lineCap: .round, lineJoin: .round))
        context.stroke(
            path,
            with: .color((lit ? midTheme.pathLit.color : midTheme.pathDim.color).opacity(lit ? 0.92 : 0.42)),
            style: StrokeStyle(lineWidth: lit ? 7 : 5, lineCap: .round, lineJoin: .round)
        )
        context.stroke(
            path,
            with: .color(Color.white.opacity(lit ? 0.28 : 0.08)),
            style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round)
        )
    }

    private func theme(forPoints points: [CGPoint]) -> MapWorldTheme {
        let midY = points.map(\.y).reduce(0, +) / CGFloat(max(points.count, 1))
        return MapWorldTheme.theme(atY: midY, layout: layout)
    }

    private func curve(through points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        guard points.count > 1 else { return path }
        if points.count == 2 {
            path.addLine(to: points[1])
            return path
        }

        let tension: CGFloat = 0.78
        for index in 0..<(points.count - 1) {
            let p0 = points[max(index - 1, 0)]
            let p1 = points[index]
            let p2 = points[index + 1]
            let p3 = points[min(index + 2, points.count - 1)]
            let c1 = CGPoint(
                x: p1.x + (p2.x - p0.x) / 6 * tension,
                y: p1.y + (p2.y - p0.y) / 6 * tension
            )
            let c2 = CGPoint(
                x: p2.x - (p3.x - p1.x) / 6 * tension,
                y: p2.y - (p3.y - p1.y) / 6 * tension
            )
            path.addCurve(to: p2, control1: c1, control2: c2)
        }
        return path
    }
}
