import SwiftUI

struct HomeView: View {
    @Environment(AppServices.self) private var services
    @State private var path: [HomeRoute] = []
    @State private var appeared = false
    @State private var mapFocusLevel: Int?

    var body: some View {
        NavigationStack(path: $path) {
            let _ = services.progress.progress
            let model = HomeViewModel(services: services)
            ScrollView {
                ViewThatFits(in: .vertical) {
                    homeStack(model, compact: false)
                    homeStack(model, compact: true)
                }
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, PathloomSpacing.lg)
                .padding(.bottom, PathloomSpacing.lg)
            }
            .scrollBounceBehavior(.basedOnSize)
            .background(PathloomPalette.background.ignoresSafeArea())
            .safeAreaPadding(.top, PathloomSpacing.sm)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .levels:
                    LevelSelectView(focusLevelID: mapFocusLevel) { levelID in
                        path.append(.game(levelID))
                    }
                case .settings:
                    SettingsView()
                case .game(let id):
                    GameView(level: services.level(id: id), onReturnToMap: { completedID in
                        mapFocusLevel = min(completedID + 1, model.totalLevels)
                        path = [.levels]
                    })
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                    appeared = true
                }
            }
        }
    }

    private func homeStack(_ model: HomeViewModel, compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: compact ? PathloomSpacing.md : PathloomSpacing.lg) {
            HomeHeaderView(
                completedCount: model.completedCount,
                totalLevels: model.totalLevels,
                onSettings: { path.append(.settings) }
            )
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : -10)

            VStack(alignment: .leading, spacing: 6) {
                Text(model.headline)
                    .font(.system(compact ? .title3 : .title2, design: .rounded).weight(.semibold))
                    .foregroundStyle(PathloomPalette.text)
                    .minimumScaleFactor(0.8)
                Text(model.subheadline)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(PathloomPalette.mutedText)
                    .minimumScaleFactor(0.85)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 8)

            HomePlayCard(model: model) {
                path.append(.game(model.continueID))
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)

            PathloomButton(title: "Journey", systemImage: "map.fill", prominent: false) {
                services.pendingMapFocus = nil
                mapFocusLevel = MapProgressManager.currentLevel(
                    progress: services.progress.progress,
                    totalLevels: model.totalLevels
                )
                path.append(.levels)
            }
            .accessibilityHint("Open the level map")
            .opacity(appeared ? 1 : 0)

            statsRow(model)
            dailyCard(model)
        }
    }

    private func statsRow(_ model: HomeViewModel) -> some View {
        HStack(spacing: PathloomSpacing.sm) {
            statTile(title: "Cleared", value: "\(model.completedCount)")
            statTile(title: "Unlocked", value: "\(model.unlockedCount)")
            statTile(title: "Streak", value: "\(model.streak)")
        }
        .opacity(appeared ? 1 : 0)
    }

    private func statTile(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(PathloomPalette.text)
                .monospacedDigit()
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(title)
                .font(.system(.caption, design: .rounded).weight(.medium))
                .foregroundStyle(PathloomPalette.mutedText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, PathloomSpacing.md)
        .background(PathloomPalette.card, in: RoundedRectangle(cornerRadius: PathloomRadius.large, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private func dailyCard(_ model: HomeViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(model.dailyTitle)
                    .font(.system(.headline, design: .rounded))
                Spacer()
                if model.isDailyCompleteToday {
                    Text("Done")
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(PathloomPalette.success)
                }
            }
            Text("A rotating puzzle from the full collection.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(PathloomPalette.mutedText)
            PathloomButton(
                title: model.isDailyCompleteToday ? "Play Again" : "Play Daily",
                systemImage: "sun.max.fill",
                prominent: false
            ) {
                path.append(.game(model.dailyLevel.id))
            }
            .accessibilityLabel("Play daily challenge, level \(model.dailyLevel.id)")
        }
        .padding(PathloomSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PathloomPalette.card, in: RoundedRectangle(cornerRadius: PathloomRadius.large, style: .continuous))
        .opacity(appeared ? 1 : 0)
    }
}

enum HomeRoute: Hashable {
    case levels
    case settings
    case game(Int)
}
