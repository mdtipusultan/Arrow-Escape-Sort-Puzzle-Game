import SwiftUI

struct LevelNodeView: View {
    let layout: MapNodeLayout
    let state: MapNodeState
    let stars: Int?
    let isHighlighted: Bool

    @State private var pulse = false
    @State private var floatUp = false

    private var theme: MapWorldTheme {
        MapWorldTheme.theme(for: layout.sectionIndex)
    }

    private var visualRadius: CGFloat {
        switch state {
        case .current: layout.radius + 6
        case .completed, .available, .locked:
            layout.isMilestone ? layout.radius : layout.radius
        }
    }

    var body: some View {
        ZStack {
            if state == .current || isHighlighted {
                Circle()
                    .fill(theme.nodeGlow.opacity(0.28))
                    .frame(width: visualRadius * 2.6, height: visualRadius * 2.6)
                    .scaleEffect(pulse ? 1.08 : 0.92)
                    .blur(radius: 1.5)
            }

            Circle()
                .fill(fillColor)
                .frame(width: visualRadius * 2, height: visualRadius * 2)
                .overlay(
                    Circle()
                        .stroke(ringColor, lineWidth: layout.isMilestone ? 3.5 : 2)
                )
                .shadow(color: shadowColor, radius: state == .current ? 10 : 4, y: 3)

            innerContent
                .foregroundStyle(contentColor)

            if layout.isMilestone {
                Image(systemName: "rhombus.fill")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(theme.secondary)
                    .offset(x: visualRadius * 0.72, y: -visualRadius * 0.72)
                    .accessibilityHidden(true)
            }
        }
        .frame(width: visualRadius * 2.8, height: visualRadius * 2.8)
        .overlay(alignment: .bottom) {
            if state == .current {
                Text("PLAY")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(theme.accent, in: Capsule())
                    .offset(y: visualRadius + 10)
            }
        }
        .offset(y: state == .current && floatUp ? -4 : 0)
        .onAppear {
            guard state == .current || isHighlighted else { return }
            withAnimation(.easeInOut(duration: 1.35).repeatForever(autoreverses: true)) {
                pulse = true
            }
            withAnimation(.easeInOut(duration: 2.1).repeatForever(autoreverses: true)) {
                floatUp = true
            }
        }
    }

    @ViewBuilder
    private var innerContent: some View {
        switch state {
        case .locked:
            Image(systemName: "lock.fill")
                .font(.system(size: layout.isMilestone ? 16 : 13, weight: .semibold))
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
            return theme.atmosphere.opacity(0.55)
        case .completed:
            return theme.accent.opacity(0.92)
        case .current:
            return theme.nodeFill
        case .available:
            return theme.nodeFill
        }
    }

    private var ringColor: Color {
        switch state {
        case .locked:
            return theme.pathDim.opacity(0.45)
        case .completed:
            return theme.secondary.opacity(0.9)
        case .current:
            return theme.nodeGlow
        case .available:
            return theme.accent.opacity(0.85)
        }
    }

    private var contentColor: Color {
        switch state {
        case .locked:
            return PathloomPalette.mutedText.opacity(0.8)
        case .completed:
            return .white
        case .current, .available:
            return PathloomPalette.text
        }
    }

    private var shadowColor: Color {
        state == .locked ? Color.black.opacity(0.08) : theme.nodeGlow.opacity(0.35)
    }
}
