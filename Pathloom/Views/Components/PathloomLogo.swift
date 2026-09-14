import SwiftUI

struct PathloomLogo: View {
    var compact: Bool = false
    var header: Bool = false

    var body: some View {
        if header {
            HStack(spacing: 10) {
                mark(size: 44)
                Text(AppConstants.gameName)
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(PathloomPalette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .layoutPriority(1)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(AppConstants.gameName)
        } else {
            VStack(spacing: compact ? 6 : 12) {
                mark(size: compact ? 64 : 112)
                Text(AppConstants.gameName)
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundStyle(PathloomPalette.text)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
            }
        }
    }

    private func mark(size: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.25, style: .continuous)
                .fill(PathloomPalette.card)
                .shadow(color: PathloomPalette.arrow.opacity(0.16), radius: size * 0.12, y: size * 0.08)
            PathloomMark()
                .padding(size * 0.14)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct PathloomMark: View {
    var body: some View {
        ZStack {
            ForEach(Array(dotPositions.enumerated()), id: \.offset) { _, point in
                Circle()
                    .fill(PathloomPalette.divider.opacity(0.7))
                    .frame(width: 3, height: 3)
                    .position(x: point.x, y: point.y)
            }
            PuzzleArrowView(direction: .up, size: 18)
                .offset(y: -22)
            PuzzleArrowView(direction: .right, size: 18)
                .offset(x: 22)
            PuzzleArrowView(direction: .down, size: 18)
                .offset(y: 22)
            PuzzleArrowView(direction: .left, size: 18)
                .offset(x: -22)
        }
        .frame(width: 84, height: 84)
        .aspectRatio(1, contentMode: .fit)
    }

    private var dotPositions: [CGPoint] {
        let cells = [-1, 0, 1]
        return cells.flatMap { row in
            cells.map { column in
                CGPoint(x: 42 + CGFloat(column) * 22, y: 42 + CGFloat(row) * 22)
            }
        }
    }
}
