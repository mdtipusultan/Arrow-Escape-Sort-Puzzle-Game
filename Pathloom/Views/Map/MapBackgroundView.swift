import SwiftUI

struct MapBackgroundView: View {
    let layout: MapLayout
    let scrollY: CGFloat
    var isPad: Bool = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            sky
            Canvas { context, size in
                drawFarRidges(in: &context, size: size)
                drawMidTerrain(in: &context, size: size)
                drawWaterAndMist(in: &context, size: size)
                drawLandmarks(in: &context, size: size)
                drawNearFoliage(in: &context, size: size)
                drawParticles(in: &context, size: size)
            }
            driftingAtmosphere
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var sky: some View {
        let height = max(layout.size.height, 1)
        let stops: [Gradient.Stop] = layout.sections.flatMap { section -> [Gradient.Stop] in
            let theme = MapWorldTheme.theme(for: section.index)
            let top = min(max(section.yTop / height, 0), 1)
            let bottom = min(max(section.yBottom / height, 0), 1)
            return [
                Gradient.Stop(color: theme.skyTop.color, location: top),
                Gradient.Stop(color: theme.skyBottom.color.opacity(0.92), location: bottom)
            ]
        }
        .sorted { $0.location < $1.location }

        return LinearGradient(
            gradient: Gradient(stops: stops.isEmpty
                ? [
                    Gradient.Stop(color: MapWorldTheme.theme(for: 0).skyTop.color, location: 0),
                    Gradient.Stop(color: MapWorldTheme.theme(for: 0).skyBottom.color, location: 1)
                ]
                : paddedStops(stops)),
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(width: layout.size.width, height: layout.size.height)
    }

    private var driftingAtmosphere: some View {
        TimelineView(.periodic(from: .now, by: 1.0 / 12.0)) { timeline in
            let phase = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                drawClouds(in: &context, size: size, phase: phase)
                drawAurora(in: &context, size: size, phase: phase)
            }
        }
    }

    private func paddedStops(_ stops: [Gradient.Stop]) -> [Gradient.Stop] {
        var unique: [Gradient.Stop] = []
        unique.reserveCapacity(stops.count + 2)
        for stop in stops {
            if let last = unique.last, abs(last.location - stop.location) < 0.0008 {
                unique[unique.count - 1] = stop
            } else {
                unique.append(stop)
            }
        }
        if let first = unique.first, first.location > 0 {
            unique.insert(Gradient.Stop(color: first.color, location: 0), at: 0)
        }
        if let last = unique.last, last.location < 1 {
            unique.append(Gradient.Stop(color: last.color, location: 1))
        }
        return unique
    }

    private func drawFarRidges(in context: inout GraphicsContext, size: CGSize) {
        let shift = parallax(0.22)
        for (index, section) in layout.sections.enumerated() {
            let theme = MapWorldTheme.theme(for: section.index)
            var ridge = Path()
            let baseY = section.yBottom + shift * 0.18
            ridge.move(to: CGPoint(x: 0, y: baseY + 40))
            ridge.addLine(to: CGPoint(x: 0, y: baseY))
            let peaks = 6 + index % 3
            for peak in 0...peaks {
                let x = size.width * CGFloat(peak) / CGFloat(peaks)
                let hashed = CGFloat(abs(MapLayoutEngine.hashJitter(index * 17 + peak)))
                let lift = 46 + hashed * 54 + CGFloat((peak * 11 + index * 7) % 28)
                let controlX = x - size.width / CGFloat(max(peaks * 2, 1))
                ridge.addQuadCurve(
                    to: CGPoint(x: x, y: baseY - (peak == 0 || peak == peaks ? 8 : lift)),
                    control: CGPoint(x: controlX, y: baseY - lift - 28)
                )
            }
            ridge.addLine(to: CGPoint(x: size.width, y: baseY + 120))
            ridge.addLine(to: CGPoint(x: 0, y: baseY + 120))
            ridge.closeSubpath()
            context.fill(ridge, with: .color(theme.terrainFar.color.opacity(0.22)))
        }
    }

    private func drawMidTerrain(in context: inout GraphicsContext, size: CGSize) {
        let shift = parallax(0.48)
        for (index, section) in layout.sections.enumerated() {
            let theme = MapWorldTheme.theme(for: section.index)
            var hill = Path()
            let baseY = (section.yTop + section.yBottom) * 0.55 + shift * 0.12
            hill.move(to: CGPoint(x: 0, y: baseY + 70))
            hill.addLine(to: CGPoint(x: 0, y: baseY))
            let humps = 4 + index % 2
            for hump in 0...humps {
                let x = size.width * CGFloat(hump) / CGFloat(humps)
                let lift = 22 + CGFloat((hump * 19 + index * 13) % 26)
                hill.addQuadCurve(
                    to: CGPoint(x: x, y: baseY + CGFloat(hump % 2) * 8),
                    control: CGPoint(x: x - size.width / CGFloat(max(humps * 2, 1)), y: baseY - lift)
                )
            }
            hill.addLine(to: CGPoint(x: size.width, y: baseY + 90))
            hill.addLine(to: CGPoint(x: 0, y: baseY + 90))
            hill.closeSubpath()
            context.fill(hill, with: .color(theme.terrainMid.color.opacity(0.14)))
        }
    }

    private func drawWaterAndMist(in context: inout GraphicsContext, size: CGSize) {
        let shift = parallax(0.36)
        for section in layout.sections {
            let theme = MapWorldTheme.theme(for: section.index)
            let height = max(section.yBottom - section.yTop, 80)
            let rect = CGRect(
                x: 0,
                y: section.yTop + shift * 0.08,
                width: size.width,
                height: height
            )
            context.fill(
                Path(rect),
                with: .linearGradient(
                    Gradient(colors: [
                        theme.fog.color.opacity(0.10),
                        Color.clear,
                        theme.atmosphere.color.opacity(0.08)
                    ]),
                    startPoint: CGPoint(x: size.width * 0.5, y: rect.minY),
                    endPoint: CGPoint(x: size.width * 0.5, y: rect.maxY)
                )
            )
        }
    }

    private func drawLandmarks(in context: inout GraphicsContext, size: CGSize) {
        let shift = parallax(0.58)
        let margin = size.width * (isPad ? 0.10 : 0.08)
        for (index, section) in layout.sections.enumerated() {
            let theme = MapWorldTheme.theme(for: section.index)
            let y = section.yBottom - 36 + shift * 0.1
            let left = margin + 8
            let right = size.width - margin - 36
            drawLandmark(
                kind: index,
                at: CGPoint(x: index % 2 == 0 ? left : right, y: y),
                theme: theme,
                in: &context
            )
            if section.levelRange.upperBound == section.levelRange.lowerBound { continue }
            let midY = (section.yTop + section.yBottom) * 0.5 + shift * 0.08
            drawLandmark(
                kind: (index + 3) % 8,
                at: CGPoint(x: index % 2 == 0 ? right : left, y: midY),
                theme: theme,
                in: &context
            )
        }
    }

    private func drawLandmark(kind: Int, at origin: CGPoint, theme: MapWorldTheme, in context: inout GraphicsContext) {
        switch kind % 8 {
        case 0:
            drawTree(at: origin, theme: theme, in: &context, scale: 1.0)
            drawTree(at: CGPoint(x: origin.x + 18, y: origin.y + 6), theme: theme, in: &context, scale: 0.72)
        case 1:
            drawTree(at: origin, theme: theme, in: &context, scale: 1.15)
            drawTree(at: CGPoint(x: origin.x + 16, y: origin.y + 10), theme: theme, in: &context, scale: 0.8)
            drawTree(at: CGPoint(x: origin.x - 12, y: origin.y + 12), theme: theme, in: &context, scale: 0.64)
        case 2:
            drawCrystal(at: origin, theme: theme, in: &context)
            drawCrystal(at: CGPoint(x: origin.x + 14, y: origin.y + 10), theme: theme, in: &context)
        case 3:
            drawCloudIsle(at: origin, theme: theme, in: &context)
        case 4:
            drawPeak(at: origin, theme: theme, in: &context)
        case 5:
            drawRuin(at: origin, theme: theme, in: &context)
        case 6:
            drawStarGate(at: origin, theme: theme, in: &context)
        default:
            drawSpire(at: origin, theme: theme, in: &context)
        }
    }

    private func drawTree(at origin: CGPoint, theme: MapWorldTheme, in context: inout GraphicsContext, scale: CGFloat) {
        let trunk = CGRect(x: origin.x + 7 * scale, y: origin.y + 18 * scale, width: 5 * scale, height: 14 * scale)
        context.fill(Path(roundedRect: trunk, cornerRadius: 1.5), with: .color(theme.terrainNear.color.opacity(0.38)))
        var canopy = Path()
        canopy.addEllipse(in: CGRect(x: origin.x, y: origin.y, width: 20 * scale, height: 22 * scale))
        canopy.addEllipse(in: CGRect(x: origin.x + 8 * scale, y: origin.y + 4 * scale, width: 16 * scale, height: 16 * scale))
        context.fill(canopy, with: .color(theme.terrainMid.color.opacity(0.32)))
    }

    private func drawCrystal(at origin: CGPoint, theme: MapWorldTheme, in context: inout GraphicsContext) {
        var gem = Path()
        gem.move(to: CGPoint(x: origin.x + 8, y: origin.y))
        gem.addLine(to: CGPoint(x: origin.x + 16, y: origin.y + 18))
        gem.addLine(to: CGPoint(x: origin.x + 8, y: origin.y + 28))
        gem.addLine(to: CGPoint(x: origin.x, y: origin.y + 18))
        gem.closeSubpath()
        context.fill(gem, with: .color(theme.sparkle.color.opacity(0.28)))
        context.stroke(gem, with: .color(theme.accent.color.opacity(0.35)), lineWidth: 1)
    }

    private func drawCloudIsle(at origin: CGPoint, theme: MapWorldTheme, in context: inout GraphicsContext) {
        var isle = Path()
        isle.addEllipse(in: CGRect(x: origin.x, y: origin.y + 8, width: 54, height: 16))
        isle.addEllipse(in: CGRect(x: origin.x + 12, y: origin.y, width: 36, height: 18))
        context.fill(isle, with: .color(theme.fog.color.opacity(0.45)))
    }

    private func drawPeak(at origin: CGPoint, theme: MapWorldTheme, in context: inout GraphicsContext) {
        var peak = Path()
        peak.move(to: CGPoint(x: origin.x, y: origin.y + 36))
        peak.addLine(to: CGPoint(x: origin.x + 16, y: origin.y))
        peak.addLine(to: CGPoint(x: origin.x + 32, y: origin.y + 36))
        peak.closeSubpath()
        context.fill(peak, with: .color(theme.terrainFar.color.opacity(0.34)))
        var snow = Path()
        snow.move(to: CGPoint(x: origin.x + 12, y: origin.y + 8))
        snow.addLine(to: CGPoint(x: origin.x + 16, y: origin.y))
        snow.addLine(to: CGPoint(x: origin.x + 20, y: origin.y + 8))
        snow.closeSubpath()
        context.fill(snow, with: .color(theme.sparkle.color.opacity(0.4)))
    }

    private func drawRuin(at origin: CGPoint, theme: MapWorldTheme, in context: inout GraphicsContext) {
        context.fill(
            Path(roundedRect: CGRect(x: origin.x, y: origin.y + 8, width: 10, height: 28), cornerRadius: 2),
            with: .color(theme.terrainNear.color.opacity(0.36))
        )
        context.fill(
            Path(roundedRect: CGRect(x: origin.x + 18, y: origin.y + 4, width: 10, height: 32), cornerRadius: 2),
            with: .color(theme.terrainNear.color.opacity(0.32))
        )
        var arch = Path()
        arch.move(to: CGPoint(x: origin.x, y: origin.y + 10))
        arch.addQuadCurve(to: CGPoint(x: origin.x + 28, y: origin.y + 10), control: CGPoint(x: origin.x + 14, y: origin.y - 6))
        context.stroke(arch, with: .color(theme.accent.color.opacity(0.28)), style: StrokeStyle(lineWidth: 4, lineCap: .round))
    }

    private func drawStarGate(at origin: CGPoint, theme: MapWorldTheme, in context: inout GraphicsContext) {
        let rect = CGRect(x: origin.x + 6, y: origin.y + 6, width: 8, height: 8)
        context.fill(Path(ellipseIn: rect), with: .color(theme.sparkle.color.opacity(0.55)))
        context.stroke(
            Path(ellipseIn: rect.insetBy(dx: -6, dy: -6)),
            with: .color(theme.secondary.color.opacity(0.28)),
            style: StrokeStyle(lineWidth: 1.4)
        )
    }

    private func drawSpire(at origin: CGPoint, theme: MapWorldTheme, in context: inout GraphicsContext) {
        var spire = Path()
        spire.move(to: CGPoint(x: origin.x + 10, y: origin.y - 8))
        spire.addLine(to: CGPoint(x: origin.x + 18, y: origin.y + 36))
        spire.addLine(to: CGPoint(x: origin.x + 2, y: origin.y + 36))
        spire.closeSubpath()
        context.fill(spire, with: .color(theme.accent.color.opacity(0.28)))
        context.fill(
            Path(ellipseIn: CGRect(x: origin.x + 6, y: origin.y - 12, width: 8, height: 8)),
            with: .color(theme.sparkle.color.opacity(0.45))
        )
    }

    private func drawNearFoliage(in context: inout GraphicsContext, size: CGSize) {
        let shift = parallax(0.82)
        let count = isPad ? 28 : 22
        for index in 0..<count {
            let sectionIndex = min(index / 3, max(layout.sections.count - 1, 0))
            let theme = MapWorldTheme.theme(for: sectionIndex)
            let side: CGFloat = index % 2 == 0 ? 1 : -1
            let x = side > 0
                ? 10 + CGFloat((index * 37) % 52)
                : size.width - 58 - CGFloat((index * 29) % 48)
            let y = CGFloat((index * 910 + 160) % max(Int(size.height - 40), 1)) + shift
            if index % 3 == 0 {
                var rock = Path()
                rock.addEllipse(in: CGRect(x: x, y: y + 12, width: 16 + CGFloat(index % 4) * 3, height: 8))
                context.fill(rock, with: .color(theme.terrainNear.color.opacity(0.22)))
            } else if index % 3 == 1 {
                context.fill(
                    Path(ellipseIn: CGRect(x: x + 4, y: y + 10, width: 5, height: 5)),
                    with: .color(theme.secondary.color.opacity(0.28))
                )
                context.fill(
                    Path(ellipseIn: CGRect(x: x + 12, y: y + 14, width: 4, height: 4)),
                    with: .color(theme.accent.color.opacity(0.22))
                )
            } else {
                drawTree(at: CGPoint(x: x, y: y), theme: theme, in: &context, scale: 0.7)
            }
        }
    }

    private func drawParticles(in context: inout GraphicsContext, size: CGSize) {
        let shift = parallax(0.40)
        let count = isPad ? 56 : 42
        for index in 0..<count {
            let sectionIndex = min(index / 6, max(layout.sections.count - 1, 0))
            let theme = MapWorldTheme.theme(for: sectionIndex)
            let y = CGFloat((index * 487 + 36) % max(Int(size.height), 1)) + shift
            let x = CGFloat((index * 211 + 19) % max(Int(size.width), 1))
            let dim: CGFloat = index % 5 == 0 ? 3.2 : 1.8
            let opacity = sectionIndex >= 6 ? 0.55 : 0.28
            context.fill(
                Path(ellipseIn: CGRect(x: x, y: y, width: dim, height: dim)),
                with: .color(theme.sparkle.color.opacity(opacity))
            )
        }
    }

    private func drawClouds(in context: inout GraphicsContext, size: CGSize, phase: TimeInterval) {
        let shift = parallax(0.32)
        let drift = CGFloat(sin(phase * 0.18))
        for index in 0..<16 {
            let sectionIndex = min(index / 2, 7)
            let theme = MapWorldTheme.theme(for: sectionIndex)
            let y = CGFloat((index * 1240 + 140) % max(Int(size.height), 1)) + shift
            let baseX = CGFloat((index * 173) % max(Int(size.width - 90), 1)) + 16
            let x = baseX + drift * (index % 2 == 0 ? 10 : -8)
            var cloud = Path()
            let w: CGFloat = 78 + CGFloat(index % 5) * 14
            cloud.addEllipse(in: CGRect(x: x, y: y, width: w, height: 20))
            cloud.addEllipse(in: CGRect(x: x + 24, y: y - 9, width: w * 0.58, height: 18))
            cloud.addEllipse(in: CGRect(x: x + 44, y: y + 3, width: w * 0.42, height: 14))
            context.fill(cloud, with: .color(theme.fog.color.opacity(sectionIndex >= 6 ? 0.10 : 0.20)))
        }
    }

    private func drawAurora(in context: inout GraphicsContext, size: CGSize, phase: TimeInterval) {
        guard layout.sections.count >= 8 else { return }
        let last = layout.sections[min(7, layout.sections.count - 1)]
        let theme = MapWorldTheme.theme(for: last.index)
        let wave = CGFloat(sin(phase * 0.22)) * 16
        var band = Path()
        let y = last.yBottom * 0.35 + last.yTop * 0.65
        band.move(to: CGPoint(x: 0, y: y))
        band.addQuadCurve(
            to: CGPoint(x: size.width, y: y + 10),
            control: CGPoint(x: size.width * 0.5, y: y - 28 + wave)
        )
        context.stroke(band, with: .color(theme.accent.color.opacity(0.16)), style: StrokeStyle(lineWidth: 18, lineCap: .round))
        context.stroke(band, with: .color(theme.secondary.color.opacity(0.10)), style: StrokeStyle(lineWidth: 8, lineCap: .round))
    }

    private func parallax(_ factor: CGFloat) -> CGFloat {
        -scrollY * (1 - factor)
    }
}
