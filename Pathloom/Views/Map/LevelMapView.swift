import SwiftUI

private struct MapScrollOffsetKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct LevelMapView: View {
    @Environment(AppServices.self) private var services
    @Environment(\.horizontalSizeClass) private var sizeClass

    var focusLevelID: Int?
    var onSelect: (Int) -> Void

    @State private var highlightID: Int?
    @State private var cloudPhase: CGFloat = 0
    @State private var scrollY: CGFloat = 0

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
            let currentID = MapProgressManager.playableLevelID(progress: progress, totalLevels: totalLevels)
            let focusID = MapProgressManager.focusLevelID(
                progress: progress,
                totalLevels: totalLevels,
                pendingReveal: focusLevelID ?? services.pendingMapFocus
            )

            ScrollViewReader { reader in
                ScrollView {
                    ZStack(alignment: .topLeading) {
                        MapBackgroundView(layout: layout, scrollY: scrollY, cloudPhase: cloudPhase)
                            .frame(width: layout.size.width, height: layout.size.height)

                        MapPathView(
                            layout: layout,
                            unlockedThrough: min(progress.highestUnlockedLevel, totalLevels),
                            revealLevelID: highlightID ?? focusID
                        )
                        .frame(width: layout.size.width, height: layout.size.height)

                        sectionLabels(layout)

                        MapJourneyMarker(
                            title: "START",
                            subtitle: "Level 1",
                            accent: MapWorldTheme.theme(for: 0).accent
                        )
                        .position(layout.startPoint)

                        MapJourneyMarker(
                            title: "HORIZON",
                            subtitle: "Level \(totalLevels)",
                            accent: MapWorldTheme.theme(for: max(layout.sections.count - 1, 0)).secondary
                        )
                        .position(layout.endPoint)

                        nodesLayer(layout: layout, progress: progress, currentID: currentID)
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
                .onPreferenceChange(MapScrollOffsetKey.self) { scrollY = $0 }
                .onAppear {
                    startClouds()
                    highlightID = focusID
                    scrollToCurrent(reader: reader, id: focusID, animated: false)
                }
                .onChange(of: focusID) { _, newValue in
                    highlightID = newValue
                    scrollToCurrent(reader: reader, id: newValue, animated: true)
                }
                .onChange(of: services.pendingMapFocus) { _, newValue in
                    guard let newValue else { return }
                    highlightID = newValue
                    scrollToCurrent(reader: reader, id: newValue, animated: true)
                    services.pendingMapFocus = nil
                }
            }
        }
        .background(PathloomPalette.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            mapStatusBar(currentID: MapProgressManager.playableLevelID(
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

    private func sectionLabels(_ layout: MapLayout) -> some View {
        ForEach(layout.sections) { section in
            MapSectionView(section: section, width: layout.size.width)
                .position(x: layout.size.width / 2, y: section.yTop)
        }
    }

    private func nodesLayer(layout: MapLayout, progress: PlayerProgress, currentID: Int) -> some View {
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
            .disabled(state == .locked)
            .position(node.position)
            .id(node.levelID)
            .accessibilityLabel(accessibilityLabel(id: node.levelID, state: state, stars: progress.stars(for: node.levelID)))
            .accessibilityHint(state == .locked ? "Complete earlier levels to unlock" : "Opens this puzzle")
            .accessibilityAddTraits(state == .current ? .isSelected : [])
        }
    }

    private func mapStatusBar(currentID: Int) -> some View {
        let progress = services.progress.progress
        return HStack {
            Text("\(progress.completedCount) cleared")
            Spacer()
            Text("Level \(currentID)")
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

    private func scrollToCurrent(reader: ScrollViewProxy, id: Int, animated: Bool) {
        let target = min(max(id, 1), totalLevels)
        let action = {
            reader.scrollTo(target, anchor: UnitPoint(x: 0.5, y: 0.46))
        }
        if animated {
            withAnimation(.easeInOut(duration: 0.85)) { action() }
        } else {
            DispatchQueue.main.async {
                action()
            }
        }
    }

    private func startClouds() {
        withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
            cloudPhase = 1
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
