import SwiftUI

struct LevelNodeView: View {
    let layout: MapNodeLayout
    let state: MapNodeState
    let stars: Int?
    let isHighlighted: Bool

    @State private var pulse = false

    private var theme: MapWorldTheme {
        MapWorldTheme.theme(for: layout.sectionIndex)
    }

    private var visualRadius: CGFloat {
        switch state {
        case .current:
            return layout.radius + 6
        case .completed, .available:
            return layout.isMilestone ? layout.radius + 1 : layout.radius
        case .locked:
            return layout.radius
        }
    }

    var body: some View {
        ZStack {
            if state == .current || isHighlighted {
                Circle()
                    .stroke(theme.nodeGlow.color.opacity(0.45), lineWidth: 2)
                    .frame(width: visualRadius * 2.7, height: visualRadius * 2.7)
                    .scaleEffect(pulse ? 1.08 : 0.90)
                    .opacity(pulse ? 0.35 : 0.8)

                Circle()
                    .fill(theme.nodeGlow.color.opacity(0.24))
                    .frame(width: visualRadius * 2.45, height: visualRadius * 2.45)
                    .scaleEffect(pulse ? 1.06 : 0.94)
                    .blur(radius: 1.2)
            }

            Circle()
                .fill(fillColor)
                .frame(width: visualRadius * 2, height: visualRadius * 2)
                .overlay(
                    Circle()
                        .stroke(ringColor, lineWidth: layout.isMilestone ? 3.4 : 2.1)
                )
                .shadow(color: shadowColor, radius: state == .current ? 10 : 4, y: 3)

            innerContent
                .foregroundStyle(contentColor)

            if layout.isMilestone {
                Image(systemName: state == .locked ? "sparkle" : "crown.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(theme.secondary.color)
                    .offset(x: visualRadius * 0.74, y: -visualRadius * 0.74)
                    .accessibilityHidden(true)
            }
        }
        .frame(width: visualRadius * 2.9, height: visualRadius * 2.9)
        .overlay(alignment: .bottom) {
            if state == .current {
                Text("PLAY")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(theme.accent.color, in: Capsule())
                    .offset(y: visualRadius + 11)
            }
        }
        .onAppear {
            guard state == .current || isHighlighted else { return }
            withAnimation(.easeInOut(duration: 1.45).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }

    @ViewBuilder
    private var innerContent: some View {
        switch state {
        case .locked:
            VStack(spacing: 1) {
                Image(systemName: "lock.fill")
                    .font(.system(size: layout.isMilestone ? 12 : 10, weight: .semibold))
                Text("\(layout.levelID)")
                    .font(.system(size: layout.isMilestone ? 12 : 11, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
        case .completed:
            VStack(spacing: 1) {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                Text("\(layout.levelID)")
                    .font(.system(size: layout.isMilestone ? 13 : 11, weight: .bold, design: .rounded))
                    .monospacedDigit()
                if let stars, stars > 0 {
                    HStack(spacing: 1) {
                        ForEach(1...3, id: \.self) { index in
                            Image(systemName: index <= stars ? "star.fill" : "star")
                                .font(.system(size: 6, weight: .bold))
                        }
                    }
                }
            }
        case .current, .available:
            Text("\(layout.levelID)")
                .font(.system(size: layout.isMilestone || state == .current ? 18 : 15, weight: .bold, design: .rounded))
                .monospacedDigit()
        }
    }

    private var fillColor: Color {
        switch state {
        case .locked:
            return theme.nodeFill.color.opacity(0.82)
        case .completed:
            return theme.accent.color.opacity(0.92)
        case .current, .available:
            return theme.nodeFill.color
        }
    }

    private var ringColor: Color {
        switch state {
        case .locked:
            return theme.pathDim.color.opacity(0.72)
        case .completed:
            return theme.secondary.color.opacity(0.9)
        case .current:
            return theme.nodeGlow.color
        case .available:
            return theme.accent.color.opacity(0.88)
        }
    }

    private var contentColor: Color {
        switch state {
        case .locked:
            return PathloomPalette.mutedText
        case .completed:
            return .white
        case .current, .available:
            return PathloomPalette.text
        }
    }

    private var shadowColor: Color {
        state == .locked ? Color.black.opacity(0.08) : theme.nodeGlow.color.opacity(0.34)
    }
}
