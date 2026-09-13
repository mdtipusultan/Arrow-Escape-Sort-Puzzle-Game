import SwiftUI

struct PathloomLogo: View {
    var compact: Bool = false

    var body: some View {
        VStack(spacing: compact ? 6 : 12) {
            ZStack {
                RoundedRectangle(cornerRadius: compact ? 16 : 28, style: .continuous)
                    .fill(PathloomPalette.card)
                    .shadow(color: PathloomPalette.primary.opacity(0.18), radius: compact ? 8 : 16, y: 6)
                PathloomMark()
                    .padding(compact ? 10 : 18)
            }
            .frame(width: compact ? 64 : 112, height: compact ? 64 : 112)
            .accessibilityHidden(true)

            Text(AppConstants.gameName)
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .foregroundStyle(PathloomPalette.text)
                .minimumScaleFactor(0.8)
        }
    }
}

struct PathloomMark: View {
    var body: some View {
        Canvas { context, size in
            let inset = size.width * 0.16
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: inset, dy: inset)
            let arrows: [(CGPoint, Angle, Color)] = [
                (CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.18), .degrees(0), PathloomPalette.primary),
                (CGPoint(x: rect.maxX - rect.width * 0.18, y: rect.midY), .degrees(90), PathloomPalette.accent),
                (CGPoint(x: rect.midX, y: rect.maxY - rect.height * 0.18), .degrees(180), PathloomPalette.secondary),
                (CGPoint(x: rect.minX + rect.width * 0.18, y: rect.midY), .degrees(270), PathloomPalette.success)
            ]
            for (center, angle, color) in arrows {
                var resolved = context
                resolved.translateBy(x: center.x, y: center.y)
                resolved.rotate(by: angle)
                resolved.fill(chevron(size: rect.width * 0.28), with: .color(color))
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func chevron(size: CGFloat) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: -size * 0.7))
        path.addLine(to: CGPoint(x: size * 0.62, y: size * 0.15))
        path.addLine(to: CGPoint(x: size * 0.22, y: size * 0.15))
        path.addLine(to: CGPoint(x: size * 0.22, y: size * 0.7))
        path.addLine(to: CGPoint(x: -size * 0.22, y: size * 0.7))
        path.addLine(to: CGPoint(x: -size * 0.22, y: size * 0.15))
        path.addLine(to: CGPoint(x: -size * 0.62, y: size * 0.15))
        path.closeSubpath()
        return path
    }
}
