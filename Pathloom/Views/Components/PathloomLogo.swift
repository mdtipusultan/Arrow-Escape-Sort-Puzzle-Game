import SwiftUI

struct PathloomLogo: View {
    var compact: Bool = false

    var body: some View {
        VStack(spacing: compact ? 6 : 12) {
            ZStack {
                RoundedRectangle(cornerRadius: compact ? 16 : 28, style: .continuous)
                    .fill(PathloomPalette.card)
                    .shadow(color: PathloomPalette.arrow.opacity(0.16), radius: compact ? 8 : 16, y: 6)
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
