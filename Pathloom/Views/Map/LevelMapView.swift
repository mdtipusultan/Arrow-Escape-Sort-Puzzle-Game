import SwiftUI

private struct MapScrollOffsetKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private enum MapFocusAnchor {
    case focus
}

struct LevelMapView: View {
    @Environment(AppServices.self) private var services
    @Environment(\.horizontalSizeClass) private var sizeClass

    var focusLevelID: Int?
    var onSelect: (Int) -> Void

    var body: some View {
        GeometryReader { proxy in
            let isPad = sizeClass == .regular && proxy.size.shortestSide >= 700
            let layout = MapLayoutEngine.layout(
                levelCount: totalLevels,
                canvasWidth: proxy.size.width,
                safeLeft: proxy.safeAreaInsets.leading,
                safeRight: proxy.safeAreaInsets.trailing,
                isPad: isPad
            )
            let progress = services.progress.progress
            let currentID = MapProgressManager.currentLevel(progress: progress, totalLevels: totalLevels)
            let focusID = MapProgressManager.focusLevelID(
                progress: progress,
                totalLevels: totalLevels,
                pendingReveal: focusLevelID ?? services.pendingMapFocus
            )

            MapJourneyScrollView(
                layout: layout,
                progress: progress,
                currentID: currentID,
                focusID: focusID,
                totalLevels: totalLevels,
                isPad: isPad,
                onSelect: onSelect
            )
        }
        .background(MapWorldTheme.theme(for: 0).skyBottom.color.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            mapStatusBar(currentID: MapProgressManager.currentLevel(
                progress: services.progress.progress,
                totalLevels: totalLevels
            ))
        }
        .navigationTitle("Journey")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }

    private var totalLevels: Int {
        LevelLoader.totalLevels(in: services.catalog)
    }

    private func mapStatusBar(currentID: Int) -> some View {
        let progress = services.progress.progress
        let lastCleared = MapProgressManager.lastCompletedLevel(progress: progress)
        return HStack {
            Text("\(progress.completedCount) cleared")
            Spacer()
            Text(lastCleared == nil ? "Level \(currentID)" : "Now \(currentID)")
                .fontWeight(.semibold)
            Spacer()
            Text("\(totalLevels) paths")
        }
        .font(.system(.caption, design: .rounded).weight(.medium))
        .foregroundStyle(PathloomPalette.text)
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(progress.completedCount) of \(totalLevels) cleared, current level \(currentID)")
    }
}

private struct MapJourneyScrollView: View {
    @Environment(AppServices.self) private var services

    let layout: MapLayout
    let progress: PlayerProgress
    let currentID: Int
    let focusID: Int
    let totalLevels: Int
    let isPad: Bool
    var onSelect: (Int) -> Void

    @State private var highlightID: Int?
    @State private var scrollY: CGFloat = 0
    @State private var isPositioned = false
    @State private var scrollAnimated = false

    private var focusedLevelID: Int {
        min(max(highlightID ?? focusID, 1), totalLevels)
    }

    var body: some View {
        ScrollViewReader { reader in
            ScrollView {
                ZStack(alignment: .topLeading) {
                    MapBackgroundView(layout: layout, scrollY: scrollY, isPad: isPad)
                        .frame(width: layout.size.width, height: layout.size.height)

                    MapPathView(
                        layout: layout,
                        unlockedThrough: min(progress.highestUnlockedLevel, totalLevels),
                        revealLevelID: highlightID ?? focusID
                    )
                    .frame(width: layout.size.width, height: layout.size.height)

                    sectionLabels

                    MapJourneyMarker(
                        title: "START",
                        subtitle: "Level 1",
                        accent: MapWorldTheme.theme(for: 0).accent.color
                    )
                    .position(layout.startPoint)

                    MapJourneyMarker(
                        title: "HORIZON",
                        subtitle: "Level \(totalLevels)",
                        accent: MapWorldTheme.theme(for: max(layout.sections.count - 1, 0)).secondary.color
                    )
                    .position(layout.endPoint)

                    focusLadder
                    nodesLayer

                    MapScrollOffsetController(
                        targetY: layout.node(for: focusedLevelID)?.position.y ?? layout.startPoint.y,
                        contentHeight: layout.size.height,
                        animated: scrollAnimated,
                        applyToken: "\(focusedLevelID)-\(Int(layout.size.width))-\(Int(layout.size.height))",
                        onApplied: {
                            Task { @MainActor in
                                isPositioned = true
                            }
                        }
                    )
                    .frame(width: 1, height: 1)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                }
                .frame(width: layout.size.width, height: layout.size.height)
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: MapScrollOffsetKey.self,
                            value: geo.frame(in: .named("levelMap")).minY
                        )
                    }
                )
            }
            .coordinateSpace(name: "levelMap")
            .scrollIndicators(.hidden)
            .opacity(isPositioned ? 1 : 0)
            .onPreferenceChange(MapScrollOffsetKey.self) { value in
                if scrollY != value {
                    scrollY = value
                }
            }
            .onAppear {
                highlightID = focusID
                scrollAnimated = false
            }
            .onChange(of: focusID) { _, newValue in
                highlightID = newValue
                scrollAnimated = false
                scrollToFocus(reader: reader, animated: false)
            }
            .onChange(of: services.pendingMapFocus) { _, newValue in
                guard let newValue else { return }
                highlightID = newValue
                scrollAnimated = true
                isPositioned = true
                scrollToFocus(reader: reader, animated: true)
                services.pendingMapFocus = nil
            }
            .task(id: "\(focusedLevelID)-\(Int(layout.size.height))") {
                highlightID = focusID
                try? await Task.sleep(for: .milliseconds(16))
                guard !Task.isCancelled else { return }
                scrollToFocus(reader: reader, animated: false)
                try? await Task.sleep(for: .milliseconds(80))
                guard !Task.isCancelled else { return }
                scrollToFocus(reader: reader, animated: false)
                try? await Task.sleep(for: .milliseconds(300))
                isPositioned = true
                services.pendingMapFocus = nil
            }
        }
    }

    /// Real layout frames (not `.position`) so `ScrollViewReader` can find the current level.
    private var focusLadder: some View {
        let y = layout.node(for: focusedLevelID)?.position.y ?? layout.startPoint.y
        return VStack(spacing: 0) {
            Rectangle()
                .fill(Color.white.opacity(0.001))
                .frame(width: 1, height: max(y, 0))
            Rectangle()
                .fill(Color.white.opacity(0.001))
                .frame(width: 8, height: 8)
                .id(MapFocusAnchor.focus)
            Rectangle()
                .fill(Color.white.opacity(0.001))
                .frame(width: 1, height: max(layout.size.height - y - 8, 0))
        }
        .frame(width: 8, height: layout.size.height, alignment: .top)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func scrollToFocus(reader: ScrollViewProxy, animated: Bool) {
        let action = {
            reader.scrollTo(MapFocusAnchor.focus, anchor: UnitPoint(x: 0.5, y: MapScrollPositioning.anchorY))
        }
        if animated {
            withAnimation(.easeInOut(duration: 0.85)) { action() }
        } else {
            action()
        }
    }

    private var sectionLabels: some View {
        ForEach(layout.sections) { section in
            let entranceY = section.yTop + (section.yBottom - section.yTop) * 0.86
            MapSectionView(section: section, width: layout.size.width)
                .position(x: layout.size.width / 2, y: entranceY)
        }
    }

    private var nodesLayer: some View {
        ForEach(layout.nodes) { node in
            let state = MapProgressManager.state(for: node.levelID, progress: progress, currentID: currentID)
            Button {
                guard state != .locked else { return }
                services.audio.play(.buttonTap)
                services.haptics.selection()
                onSelect(node.levelID)
            } label: {
                LevelNodeView(
                    layout: node,
                    state: state,
                    stars: progress.stars(for: node.levelID),
                    isHighlighted: highlightID == node.levelID
                )
            }
            .buttonStyle(.plain)
            .allowsHitTesting(state != .locked)
            .position(node.position)
            .accessibilityLabel(accessibilityLabel(id: node.levelID, state: state, stars: progress.stars(for: node.levelID)))
            .accessibilityHint(state == .locked ? "Complete earlier levels to unlock" : "Opens this puzzle")
            .accessibilityAddTraits(state == .current ? .isSelected : [])
        }
    }

    private func accessibilityLabel(id: Int, state: MapNodeState, stars: Int?) -> String {
        switch state {
        case .locked:
            return "Level \(id), locked"
        case .completed:
            if let stars {
                return "Level \(id), completed, \(stars) stars"
            }
            return "Level \(id), completed"
        case .current:
            return "Level \(id), current, play"
        case .available:
            return "Level \(id), available"
        }
    }
}

private extension CGSize {
    var shortestSide: CGFloat { min(width, height) }
}
