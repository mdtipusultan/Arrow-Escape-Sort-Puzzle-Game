import SwiftUI

struct HomePlayCard: View {
    let model: HomeViewModel
    var onContinue: () -> Void

    @State private var drift = false

    var body: some View {
        VStack(spacing: PathloomSpacing.md) {
            arrowCluster
            Text("Level \(model.continueID)")
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .foregroundStyle(PathloomPalette.text)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .monospacedDigit()

            VStack(spacing: 8) {
                ProgressView(value: model.fractionComplete)
                    .tint(PathloomPalette.primary)
                    .animation(.easeInOut(duration: 0.45), value: model.fractionComplete)
                    .accessibilityLabel("Progress")
                    .accessibilityValue("\(model.completedCount) of \(model.totalLevels) completed")
                Text("\(model.completedCount) / \(model.totalLevels)")
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundStyle(PathloomPalette.mutedText)
                    .monospacedDigit()
            }

            if let stars = model.continueLevelStars {
                HStack(spacing: 4) {
                    ForEach(1...3, id: \.self) { index in
                        Image(systemName: index <= stars ? "star.fill" : "star")
                            .font(.system(size: 12, weight: .semibold))
                    }
                }
                .foregroundStyle(PathloomPalette.secondary)
                .accessibilityLabel("\(stars) stars on this level")
            } else if let best = model.continueLevelBestMoves {
                Text("Best \(best) moves")
                    .font(.system(.footnote, design: .rounded).weight(.medium))
                    .foregroundStyle(PathloomPalette.secondary)
            }

            PathloomButton(
                title: model.continueTitle,
                systemImage: model.hasStartedGame ? "arrow.forward.circle.fill" : "play.fill"
            ) {
                onContinue()
            }
            .accessibilityLabel(model.continueAccessibilityLabel)
        }
        .padding(PathloomSpacing.lg)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: PathloomRadius.extraLarge, style: .continuous)
                .fill(PathloomPalette.card)
                .shadow(color: PathloomPalette.primary.opacity(0.12), radius: 18, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: PathloomRadius.extraLarge, style: .continuous)
                .stroke(PathloomPalette.primary.opacity(0.12), lineWidth: 1)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                drift = true
            }
        }
    }

    private var arrowCluster: some View {
        HStack(spacing: PathloomSpacing.lg) {
            PuzzleArrowView(direction: .left, size: 22)
                .offset(y: drift ? -5 : 5)
            PuzzleArrowView(direction: .up, size: 28)
                .offset(y: drift ? 4 : -4)
            PuzzleArrowView(direction: .right, size: 22)
                .offset(y: drift ? -5 : 5)
        }
        .accessibilityHidden(true)
    }
}
