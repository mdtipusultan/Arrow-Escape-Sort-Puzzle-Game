import SwiftUI

private struct MapScrollOffsetKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct MapScrollAnchorID: Hashable {
    let levelID: Int
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
    @State private var didAutoScroll = false
    @State private var isPositioned = false

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

                    scrollAnchors
                    nodesLayer
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
            .onPreferenceChange(MapScrollOffsetKey.self) { scrollY = $0 }
            .task {
                await performInitialScrollIfNeeded(reader: reader, id: focusID)
                isPositioned = true
            }
            .onChange(of: services.pendingMapFocus) { _, newValue in
                guard let newValue else { return }
                highlightID = newValue
                scrollToCurrent(reader: reader, id: newValue, animated: true)
                services.pendingMapFocus = nil
            }
        }
    }

    private var sectionLabels: some View {
        ForEach(layout.sections) { section in
            let entranceY = section.yTop + (section.yBottom - section.yTop) * 0.86
            MapSectionView(section: section, width: layout.size.width)
                .position(x: layout.size.width / 2, y: entranceY)
        }
    }

    private var scrollAnchors: some View {
        ForEach(layout.nodes) { node in
            Color.clear
                .frame(width: 1, height: 1)
                .position(node.position)
                .id(MapScrollAnchorID(levelID: node.levelID))
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

    @MainActor
    private func performInitialScrollIfNeeded(reader: ScrollViewProxy, id: Int) async {
        guard !didAutoScroll else { return }
        didAutoScroll = true
        highlightID = id
        try? await Task.sleep(for: .milliseconds(16))
        scrollToCurrent(reader: reader, id: id, animated: false)
        try? await Task.sleep(for: .milliseconds(60))
        scrollToCurrent(reader: reader, id: id, animated: false)
        if services.pendingMapFocus != nil {
            services.pendingMapFocus = nil
        }
    }

    private func scrollToCurrent(reader: ScrollViewProxy, id: Int, animated: Bool) {
        let target = min(max(id, 1), totalLevels)
        let action = {
            reader.scrollTo(MapScrollAnchorID(levelID: target), anchor: UnitPoint(x: 0.5, y: 0.38))
        }
        if animated {
            withAnimation(.easeInOut(duration: 0.85)) { action() }
        } else {
            action()
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
