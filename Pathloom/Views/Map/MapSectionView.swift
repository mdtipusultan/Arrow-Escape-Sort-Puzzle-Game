import SwiftUI

struct MapSectionView: View {
    let section: MapSectionLayout
    let width: CGFloat

    private var theme: MapWorldTheme {
        MapWorldTheme.theme(for: section.index)
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(section.subtitle.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(1.7)
                .foregroundStyle(theme.accent.color.opacity(0.88))
            Text(section.title)
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundStyle(PathloomPalette.text.opacity(0.88))
                .multilineTextAlignment(.center)
            Text("Levels \(section.levelRange.lowerBound)–\(section.levelRange.upperBound)")
                .font(.system(.caption, design: .rounded).weight(.medium))
                .foregroundStyle(PathloomPalette.mutedText)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(theme.accent.color.opacity(0.20), lineWidth: 1)
                )
        )
        .frame(width: width)
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(section.title), \(section.subtitle), levels \(section.levelRange.lowerBound) to \(section.levelRange.upperBound)")
    }
}

struct MapJourneyMarker: View {
    let title: String
    let subtitle: String
    let accent: Color

    var body: some View {
        VStack(spacing: 6) {
            Circle()
                .fill(accent.opacity(0.18))
                .frame(width: 18, height: 18)
                .overlay(
                    Circle()
                        .fill(accent)
                        .frame(width: 8, height: 8)
                )
            Text(title)
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundStyle(PathloomPalette.text)
            Text(subtitle)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(PathloomPalette.mutedText)
        }
        .allowsHitTesting(false)
    }
}
