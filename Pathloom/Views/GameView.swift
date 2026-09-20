import SwiftUI

struct GameView: View {
    @Environment(AppServices.self) private var services
    @Environment(\.dismiss) private var dismiss

    let level: Level
    var onReturnToMap: ((Int) -> Void)?
    @State private var viewModel: GameViewModel?

    var body: some View {
        Group {
            if let viewModel {
                gameContent(viewModel)
            } else {
                PathloomPalette.background
                    .ignoresSafeArea()
                    .onAppear {
                        viewModel = GameViewModel(level: level, services: services)
                    }
            }
        }
    }

    private func gameContent(_ viewModel: GameViewModel) -> some View {
        GeometryReader { proxy in
            let boardSide = boardMeasurement(in: proxy.size)
            VStack(spacing: PathloomSpacing.md) {
                header(viewModel)
                if let tutorialMessage = viewModel.tutorialMessage {
                    Text(tutorialMessage)
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                        .foregroundStyle(PathloomPalette.mutedText)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal)
                }
                GameBoardView(viewModel: viewModel)
                    .frame(width: boardSide, height: boardSide)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityLabel("Puzzle board, \(viewModel.remainingCount) arrows remaining")
                footer(viewModel)
            }
            .padding(.horizontal, PathloomSpacing.md)
            .padding(.bottom, PathloomSpacing.md)
        }
        .background(PathloomPalette.background.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .overlay {
            if viewModel.state == .paused {
                PauseView(
                    onResume: { viewModel.resume() },
                    onRestart: { viewModel.restart() },
                    onExit: { dismiss() }
                )
            }
        }
        .overlay {
            if viewModel.state == .completed {
                LevelCompleteView(
                    moves: viewModel.moveCount,
                    parMoves: viewModel.level.parMoves,
                    stars: viewModel.engine.starRating,
                    best: services.progress.progress.best(for: viewModel.level.id),
                    hasNext: viewModel.level.id < AppConstants.totalLevels,
                    onContinue: { returnToMap(from: viewModel.level.id) },
                    onReplay: { viewModel.restart() }
                )
            }
        }
        #if DEBUG
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink("Debug") {
                    DeveloperMenuView(viewModel: viewModel) { id in
                        self.viewModel = GameViewModel(level: services.level(id: id), services: services)
                    }
                }
            }
        }
        #endif
    }

    private func header(_ viewModel: GameViewModel) -> some View {
        HStack {
            Button {
                viewModel.pause()
            } label: {
                Image(systemName: "pause.fill")
                    .frame(width: AppConstants.minimumTouchTarget, height: AppConstants.minimumTouchTarget)
            }
            .accessibilityLabel("Pause")

            Spacer()
            Text("Level \(viewModel.level.id)")
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(PathloomPalette.text)
            Spacer()
            Color.clear.frame(width: AppConstants.minimumTouchTarget, height: AppConstants.minimumTouchTarget)
        }
        .foregroundStyle(PathloomPalette.primary)
    }

    private func footer(_ viewModel: GameViewModel) -> some View {
        VStack(spacing: 12) {
            Text("Moves \(viewModel.moveCount)  ·  Par \(viewModel.level.parMoves)")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(PathloomPalette.text)
                .accessibilityLabel("Moves \(viewModel.moveCount), \(viewModel.remainingCount) remaining")

            HStack(spacing: 12) {
                PathloomButton(title: "Restart", systemImage: "arrow.counterclockwise", prominent: false) {
                    viewModel.restart()
                }
                PathloomButton(title: "Undo", systemImage: "arrow.uturn.backward", prominent: false) {
                    viewModel.undo()
                }
                .opacity(viewModel.canUndo ? 1 : 0.45)
                .disabled(!viewModel.canUndo)
            }
        }
    }

    private func boardMeasurement(in size: CGSize) -> CGFloat {
        let reserved: CGFloat = 220
        let widthCap = min(size.width * AppConstants.Board.widthScreenFactor, AppConstants.Board.maximumWidth)
        let heightCap = max(size.height - reserved, 160)
        return min(widthCap, heightCap)
    }

    private func returnToMap(from completedID: Int) {
        if let onReturnToMap {
            onReturnToMap(completedID)
        } else {
            dismiss()
        }
    }
}
