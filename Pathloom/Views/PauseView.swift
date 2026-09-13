import SwiftUI

struct PauseView: View {
    var onResume: () -> Void
    var onRestart: () -> Void
    var onExit: () -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
                .overlay(Color.black.opacity(0.25).ignoresSafeArea())

            VStack(spacing: PathloomSpacing.md) {
                Text("Paused")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundStyle(PathloomPalette.text)
                PathloomButton(title: "Resume", systemImage: "play.fill", action: onResume)
                PathloomButton(title: "Restart", systemImage: "arrow.counterclockwise", prominent: false, action: onRestart)
                PathloomButton(title: "Exit Level", systemImage: "rectangle.portrait.and.arrow.right", prominent: false, action: onExit)
            }
            .padding(PathloomSpacing.lg)
            .background(PathloomPalette.card, in: RoundedRectangle(cornerRadius: PathloomRadius.extraLarge, style: .continuous))
            .padding(PathloomSpacing.xl)
            .accessibilityAddTraits(.isModal)
        }
    }
}
