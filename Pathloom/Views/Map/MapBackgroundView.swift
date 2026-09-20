import SwiftUI

struct MapBackgroundView: View {
    let layout: MapLayout
    let scrollY: CGFloat
    let cloudPhase: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            sectionAtmosphere
            Canvas { context, size in
                drawTerrain(in: &context, size: size, factor: 0.40)
                drawIslands(in: &context, size: size, factor: 0.70)
                drawSparkles(in: &context, size: size, factor: 0.55)
                drawChevrons(in: &context, size: size, factor: 0.78)
            }
            clouds
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var sectionAtmosphere: some View {
        ZStack(alignment: .topLeading) {
            PathloomPalette.background
            ForEach(layout.sections) { section in
                let theme = MapWorldTheme.theme(for: section.index)
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.atmosphere.opacity(0.55),
                                theme.atmosphere.opacity(0.18),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: layout.size.width, height: max(section.yBottom - section.yTop + 80, 120))
                    .offset(y: section.yTop - 40)
            }
        }
    }

    private var clouds: some View {
        Canvas { context, size in
            let shift = parallax(0.48)
            for index in 0..<18 {
                let seed = CGFloat((index * 97) % 280)
                let y = CGFloat((index * 1130 + 180) % max(Int(size.height), 1)) + shift
                let x = (seed.truncatingRemainder(dividingBy: size.width * 0.7)) + 30 + cloudPhase * (index % 2 == 0 ? 14 : -10)
                let theme = MapWorldTheme.theme(for: min(index / 2, 8))
                var cloud = Path()
                let w: CGFloat = 70 + CGFloat(index % 5) * 12
                cloud.addEllipse(in: CGRect(x: x, y: y, width: w, height: 22))
                cloud.addEllipse(in: CGRect(x: x + 22, y: y - 10, width: w * 0.62, height: 20))
                cloud.addEllipse(in: CGRect(x: x + 40, y: y + 2, width: w * 0.5, height: 16))
                context.fill(cloud, with: .color(theme.sparkle.opacity(0.16)))
            }
        }
    }

    private func drawTerrain(in context: inout GraphicsContext, size: CGSize, factor: CGFloat) {
        let shift = parallax(factor)
        for (index, section) in layout.sections.enumerated() {
            let theme = MapWorldTheme.theme(for: section.index)
            var ridge = Path()
            let baseY = section.yBottom + shift * 0.2
            ridge.move(to: CGPoint(x: 0, y: baseY))
            let peaks = 5 + index % 3
            for peak in 0...peaks {
                let x = size.width * CGFloat(peak) / CGFloat(peaks)
                let lift = 28 + CGFloat((peak * 13 + index * 9) % 36)
                ridge.addQuadCurve(
                    to: CGPoint(x: x, y: baseY - (peak == peaks ? 0 : lift)),
                    control: CGPoint(x: x - size.width / CGFloat(peaks * 2), y: baseY - lift - 16)
                )
            }
            ridge.addLine(to: CGPoint(x: size.width, y: baseY + 90))
            ridge.addLine(to: CGPoint(x: 0, y: baseY + 90))
            ridge.closeSubpath()
            context.fill(ridge, with: .color(theme.terrain.opacity(0.12)))
        }
    }

    private func drawIslands(in context: inout GraphicsContext, size: CGSize, factor: CGFloat) {
        let shift = parallax(factor)
        for index in 0..<24 {
            let section = index % max(layout.sections.count, 1)
            let theme = MapWorldTheme.theme(for: section)
            let y = CGFloat((index * 830 + 220) % max(Int(size.height - 80), 1)) + shift
            let x = CGFloat((index * 173) % max(Int(size.width - 90), 1)) + 20
            var isle = Path()
            isle.addEllipse(in: CGRect(x: x, y: y, width: 54 + CGFloat(index % 4) * 10, height: 18))
            context.fill(isle, with: .color(theme.terrain.opacity(0.16)))
            var shadow = Path()
            shadow.addEllipse(in: CGRect(x: x + 8, y: y + 10, width: 38, height: 8))
            context.fill(shadow, with: .color(theme.accent.opacity(0.08)))
        }
    }

    private func drawSparkles(in context: inout GraphicsContext, size: CGSize, factor: CGFloat) {
        let shift = parallax(factor)
        for index in 0..<40 {
            let section = min(index / 5, 8)
            let theme = MapWorldTheme.theme(for: section)
            let y = CGFloat((index * 497 + 40) % max(Int(size.height), 1)) + shift
            let x = CGFloat((index * 239 + 17) % max(Int(size.width), 1))
            let dim: CGFloat = index % 4 == 0 ? 3.4 : 2.0
            let rect = CGRect(x: x, y: y, width: dim, height: dim)
            context.fill(Path(ellipseIn: rect), with: .color(theme.sparkle.opacity(0.45)))
        }
    }

    private func drawChevrons(in context: inout GraphicsContext, size: CGSize, factor: CGFloat) {
        let shift = parallax(factor)
        for index in 0..<12 {
            let theme = MapWorldTheme.theme(for: index % 9)
            let y = CGFloat((index * 1540 + 300) % max(Int(size.height), 1)) + shift
            let x = CGFloat((index % 2 == 0 ? 28 : size.width - 46))
            var chevron = Path()
            chevron.move(to: CGPoint(x: x, y: y + 10))
            chevron.addLine(to: CGPoint(x: x + 8, y: y))
            chevron.addLine(to: CGPoint(x: x + 16, y: y + 10))
            context.stroke(chevron, with: .color(theme.accent.opacity(0.18)), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
    }

    private func parallax(_ factor: CGFloat) -> CGFloat {
        -scrollY * (1 - factor)
    }
}
