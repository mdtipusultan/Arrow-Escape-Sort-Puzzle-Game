import SwiftUI

struct HomeView: View {
    @Environment(AppServices.self) private var services
    @State private var path: [HomeRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            let model = HomeViewModel(services: services)
            ScrollView {
                VStack(alignment: .leading, spacing: PathloomSpacing.lg) {
                    HStack(alignment: .center) {
                        PathloomLogo(compact: true)
                        Spacer()
                        Button {
                            services.audio.play(.buttonTap)
                            path.append(.settings)
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(PathloomPalette.primary)
                                .frame(width: AppConstants.minimumTouchTarget, height: AppConstants.minimumTouchTarget)
                                .background(PathloomPalette.card, in: Circle())
                        }
                        .accessibilityLabel("Settings")
                    }

                    Text("Weave a path off the board.")
                        .font(.system(.title3, design: .rounded).weight(.medium))
                        .foregroundStyle(PathloomPalette.mutedText)

                    VStack(spacing: PathloomSpacing.md) {
                        PathloomButton(title: "Play", systemImage: "play.fill") {
                            path.append(.levels)
                        }
                        PathloomButton(
                            title: "Continue Level \(model.continueID)",
                            systemImage: "arrow.forward.circle.fill",
                            prominent: false
                        ) {
                            path.append(.game(model.continueID))
                        }
                    }

                    progressCard(model)
                    dailyCard(model)
                }
                .padding(PathloomSpacing.lg)
            }
            .background(PathloomPalette.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .levels:
                    LevelSelectView { levelID in
                        path.append(.game(levelID))
                    }
                case .settings:
                    SettingsView()
                case .game(let id):
                    GameView(level: services.level(id: id))
                }
            }
        }
    }

    private func progressCard(_ model: HomeViewModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Progress")
                .font(.system(.headline, design: .rounded))
            Text("\(model.completedCount) / \(model.totalCount) completed")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(PathloomPalette.mutedText)
            ProgressView(value: Double(model.completedCount), total: Double(max(model.totalCount, 1)))
                .tint(PathloomPalette.primary)
            if model.streak > 0 {
                Text("Streak \(model.streak)")
                    .font(.system(.footnote, design: .rounded).weight(.medium))
                    .foregroundStyle(PathloomPalette.secondary)
            }
        }
        .padding(PathloomSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PathloomPalette.card, in: RoundedRectangle(cornerRadius: PathloomRadius.large, style: .continuous))
    }

    private func dailyCard(_ model: HomeViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(model.dailyTitle)
                .font(.system(.headline, design: .rounded))
            Text("A rotating puzzle from the full collection.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(PathloomPalette.mutedText)
            PathloomButton(title: "Play Daily", systemImage: "sun.max.fill", prominent: false) {
                path.append(.game(model.dailyLevel.id))
            }
        }
        .padding(PathloomSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PathloomPalette.card, in: RoundedRectangle(cornerRadius: PathloomRadius.large, style: .continuous))
    }
}

enum HomeRoute: Hashable {
    case levels
    case settings
    case game(Int)
}
