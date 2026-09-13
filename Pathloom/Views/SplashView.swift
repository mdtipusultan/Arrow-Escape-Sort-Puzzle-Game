import SwiftUI

struct SplashView: View {
    var onFinished: () -> Void
    @State private var logoOpacity = 0.0
    @State private var markOffset: CGFloat = 12
    @State private var titleOpacity = 0.0
    @State private var progress: Double = 0.08

    var body: some View {
        VStack(spacing: PathloomSpacing.lg) {
            Spacer()
            PathloomMark()
                .frame(width: 120, height: 120)
                .offset(y: markOffset)
                .opacity(logoOpacity)
            Text(AppConstants.gameName)
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .foregroundStyle(PathloomPalette.text)
                .opacity(titleOpacity)
            Text(AppConstants.tagline)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(PathloomPalette.mutedText)
                .opacity(titleOpacity)
            Spacer()
            ProgressView(value: progress)
                .tint(PathloomPalette.primary)
                .padding(.horizontal, 80)
                .padding(.bottom, 48)
                .accessibilityLabel("Loading")
        }
        .padding()
        .task {
            withAnimation(.easeInOut(duration: 0.35)) {
                logoOpacity = 1
                markOffset = 0
            }
            try? await Task.sleep(for: .milliseconds(280))
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                titleOpacity = 1
            }
            withAnimation(.easeInOut(duration: 0.7)) {
                progress = 1
            }
            try? await Task.sleep(for: .seconds(AppConstants.splashDuration))
            onFinished()
        }
    }
}
