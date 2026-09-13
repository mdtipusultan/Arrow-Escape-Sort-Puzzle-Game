import SwiftUI

struct OnboardingView: View {
    var onFinished: () -> Void
    @Environment(AppServices.self) private var services
    @State private var page = 0

    private let pages: [(title: String, body: String)] = [
        ("Think Ahead", "Each arrow slips off the board only if nothing stands in its way. Order is everything."),
        ("Find the Path", "Tap an arrow facing a clear route to the edge. It glides out and the board opens up."),
        ("Clear Every Arrow", "Remove them all to complete the weave. Later boards hide longer chains and clever traps.")
    ]

    var body: some View {
        VStack(spacing: PathloomSpacing.lg) {
            HStack {
                Spacer()
                Button("Skip") {
                    services.audio.play(.onboardingNext)
                    onFinished()
                }
                .font(.system(.body, design: .rounded).weight(.semibold))
                .foregroundStyle(PathloomPalette.mutedText)
                .frame(minHeight: AppConstants.minimumTouchTarget)
            }

            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { index in
                    VStack(spacing: PathloomSpacing.md) {
                        onboardingArt(for: index)
                            .frame(height: 220)
                        Text(pages[index].title)
                            .font(.system(.title, design: .rounded).weight(.bold))
                            .foregroundStyle(PathloomPalette.text)
                        Text(pages[index].body)
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(PathloomPalette.mutedText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, PathloomSpacing.lg)
                    }
                    .tag(index)
                    .padding()
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            if page == pages.count - 1 {
                PathloomButton(title: "Get Started", systemImage: "arrow.right") {
                    services.audio.play(.onboardingNext)
                    onFinished()
                }
            } else {
                PathloomButton(title: "Next", systemImage: "chevron.right") {
                    services.audio.play(.onboardingNext)
                    services.haptics.selection()
                    withAnimation { page += 1 }
                }
            }
        }
        .padding(PathloomSpacing.lg)
    }

    @ViewBuilder
    private func onboardingArt(for index: Int) -> some View {
        switch index {
        case 0:
            HStack(spacing: 12) {
                miniArrow(.right, color: PathloomPalette.accent)
                miniArrow(.up, color: PathloomPalette.primary)
                miniArrow(.left, color: PathloomPalette.success)
            }
        case 1:
            PathDemoView()
        default:
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    miniArrow(.down, color: PathloomPalette.secondary)
                    miniArrow(.right, color: PathloomPalette.accent)
                }
                Text("Choose the order")
                    .font(.system(.footnote, design: .rounded).weight(.medium))
                    .foregroundStyle(PathloomPalette.mutedText)
            }
        }
    }

    private func miniArrow(_ direction: Direction, color: Color) -> some View {
        Image(systemName: "arrow.up")
            .font(.system(size: 34, weight: .bold))
            .foregroundStyle(color)
            .rotationEffect(.radians(Double(direction.rotationRadians)))
            .frame(width: 64, height: 64)
            .background(PathloomPalette.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct PathDemoView: View {
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(PathloomPalette.card)
            HStack(spacing: 18) {
                Image(systemName: "arrow.right")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(PathloomPalette.accent)
                    .offset(x: offset)
                    .opacity(opacity)
                Spacer()
                Capsule()
                    .fill(PathloomPalette.primary.opacity(0.2))
                    .frame(width: 8, height: 48)
            }
            .padding(36)
        }
        .padding(.horizontal, 24)
        .task {
            while !Task.isCancelled {
                offset = 0
                opacity = 1
                withAnimation(.easeIn(duration: 0.55)) {
                    offset = 90
                    opacity = 0.15
                }
                try? await Task.sleep(for: .seconds(1.1))
            }
        }
    }
}
