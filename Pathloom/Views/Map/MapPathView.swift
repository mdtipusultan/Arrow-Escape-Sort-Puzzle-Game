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
                let lit = curve(through: Array(points.prefix(split + 1)))
                strokePath(lit, in: &context, lit: true)
            }

            if split < points.count {
                let dimPoints = Array(points.suffix(from: max(split - 1, 0)))
                let dim = curve(through: dimPoints)
                strokePath(dim, in: &context, lit: false)
            }

            if let reveal = revealLevelID, let node = layout.node(for: reveal) {
                let glow = Path(ellipseIn: CGRect(
                    x: node.position.x - node.radius - 10,
                    y: node.position.y - node.radius - 10,
                    width: (node.radius + 10) * 2,
                    height: (node.radius + 10) * 2
                ))
                let theme = MapWorldTheme.theme(for: node.sectionIndex)
                context.fill(glow, with: .color(theme.nodeGlow.opacity(0.16)))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func curve(through points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        if points.count == 2 {
            path.addLine(to: points[1])
            return path
        }
        for index in 1..<points.count {
            let previous = points[index - 1]
            let current = points[index]
            let dx = current.x - previous.x
            let dy = current.y - previous.y
            let lift: CGFloat = index % 2 == 0 ? 22 : -22
            let c1 = CGPoint(
                x: previous.x + dx * 0.22 + lift,
                y: previous.y + dy * 0.28
            )
            let c2 = CGPoint(
                x: previous.x + dx * 0.78 - lift,
                y: previous.y + dy * 0.72
            )
            path.addCurve(to: current, control1: c1, control2: c2)
        }
        return path
    }

    private func strokePath(_ path: Path, in context: inout GraphicsContext, lit: Bool) {
        let topTheme = MapWorldTheme.theme(for: max(layout.sections.count - 1, 0))
        let bottomTheme = MapWorldTheme.theme(for: 0)
        let glow = lit ? topTheme.nodeGlow.opacity(0.22) : Color.black.opacity(0.05)
        let core = lit ? topTheme.pathLit : topTheme.pathDim.opacity(0.55)

        context.stroke(path, with: .color(glow), style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
        context.stroke(
            path,
            with: .linearGradient(
                Gradient(colors: lit
                    ? [topTheme.pathLit, bottomTheme.pathLit]
                    : [topTheme.pathDim.opacity(0.45), bottomTheme.pathDim.opacity(0.40)]),
                startPoint: CGPoint(x: layout.size.width * 0.5, y: 0),
                endPoint: CGPoint(x: layout.size.width * 0.5, y: layout.size.height)
            ),
            style: StrokeStyle(lineWidth: lit ? 7 : 5, lineCap: .round, lineJoin: .round)
        )
        context.stroke(
            path,
            with: .color(core.opacity(lit ? 0.85 : 0.5)),
            style: StrokeStyle(lineWidth: 3.2, lineCap: .round, lineJoin: .round)
        )
    }
}
