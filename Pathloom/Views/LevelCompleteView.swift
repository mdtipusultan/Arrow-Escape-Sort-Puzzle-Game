import SwiftUI

struct LevelCompleteView: View {
    let moves: Int
    let best: Int?
    let hasNext: Bool
    var onNext: () -> Void
    var onReplay: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.28).ignoresSafeArea()
            VStack(spacing: PathloomSpacing.md) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(PathloomPalette.success)
                    .scaleEffect(appeared ? 1 : 0.6)
                    .animation(.spring(response: 0.45, dampingFraction: 0.7), value: appeared)
                Text("Level Complete")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundStyle(PathloomPalette.text)
                    .minimumScaleFactor(0.8)
                HStack(spacing: PathloomSpacing.xl) {
                    stat("Moves", "\(moves)")
                    stat("Best", best.map(String.init) ?? "—")
                }
                if hasNext {
                    PathloomButton(title: "Next Level", systemImage: "arrow.right", action: onNext)
                }
                PathloomButton(title: "Replay", systemImage: "arrow.counterclockwise", prominent: false, action: onReplay)
            }
            .padding(PathloomSpacing.lg)
            .background(PathloomPalette.card, in: RoundedRectangle(cornerRadius: PathloomRadius.extraLarge, style: .continuous))
            .padding(PathloomSpacing.xl)
        }
        .onAppear { appeared = true }
        .accessibilityAddTraits(.isModal)
    }

    private func stat(_ title: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(.caption, design: .rounded).weight(.medium))
                .foregroundStyle(PathloomPalette.mutedText)
            Text(value)
                .font(.system(.title, design: .rounded).weight(.bold))
                .foregroundStyle(PathloomPalette.text)
        }
        .accessibilityElement(children: .combine)
    }
}
