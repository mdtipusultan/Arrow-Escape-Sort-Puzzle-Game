import SwiftUI

struct OnboardingView: View {
    var onFinished: () -> Void
    @Environment(AppServices.self) private var services
    @State private var page = 0

    private let pages: [(title: String, body: String)] = [
        ("Think Ahead", "Each arrow slips off the board only if nothing stands in its way. Order is everything."),
        ("Find the Path", "Tap an arrow facing a clear route to the edge. It glides from dot to dot until it leaves."),
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
            dottedCard {
                HStack(spacing: 28) {
                    PuzzleArrowView(direction: .left, size: 32)
                    PuzzleArrowView(direction: .up, size: 32)
                    PuzzleArrowView(direction: .right, size: 32)
                }
            }
        case 1:
            PathDemoView()
        default:
            dottedCard {
                HStack(spacing: 18) {
                    PuzzleArrowView(direction: .up, style: .turnRight, size: 28)
                    PuzzleArrowView(direction: .right, size: 28)
                    PuzzleArrowView(direction: .down, style: .turnLeft, size: 28)
                    PuzzleArrowView(direction: .left, size: 28)
                }
            }
        }
    }

    private func dottedCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(PathloomPalette.card)
            DottedField()
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            content()
        }
        .padding(.horizontal, 24)
    }
}

private struct DottedField: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 18
            var y: CGFloat = 16
            while y < size.height - 10 {
                var x: CGFloat = 16
                while x < size.width - 10 {
                    let rect = CGRect(x: x, y: y, width: 3, height: 3)
                    context.fill(Path(ellipseIn: rect), with: .color(PathloomPalette.divider.opacity(0.85)))
                    x += spacing
                }
                y += spacing
            }
        }
        .opacity(0.9)
    }
}

private struct PathDemoView: View {
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(PathloomPalette.card)
            DottedField()
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            PuzzleArrowView(direction: .right, size: 36)
                .offset(x: offset - 70)
                .opacity(opacity)
        }
        .padding(.horizontal, 24)
        .task {
            while !Task.isCancelled {
                offset = 0
                opacity = 1
                withAnimation(.easeIn(duration: 0.85)) {
                    offset = 150
                    opacity = 0.15
                }
                try? await Task.sleep(for: .seconds(1.35))
            }
        }
    }
}
