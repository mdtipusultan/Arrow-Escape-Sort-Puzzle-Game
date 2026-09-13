#if DEBUG
import SwiftUI

struct DeveloperMenuView: View {
    @Environment(AppServices.self) private var services
    var viewModel: GameViewModel
    var onJump: (Int) -> Void

    @State private var jumpText = "1"
    @State private var validation: String = ""

    var body: some View {
        Form {
            Section("Level") {
                TextField("Jump to level", text: $jumpText)
                    .keyboardType(.numberPad)
                Button("Jump") {
                    if let id = Int(jumpText) {
                        services.progress.jumpTo(levelID: id, totalLevels: AppConstants.totalLevels)
                        onJump(id)
                    }
                }
                Button("Unlock all") {
                    services.progress.unlockAll(totalLevels: AppConstants.totalLevels)
                }
                Button("Reset progress") {
                    services.progress.reset()
                }
            }
            Section("Board") {
                Toggle("Show coordinates", isOn: Binding(
                    get: { viewModel.debugOverlay },
                    set: { viewModel.debugOverlay = $0 }
                ))
                Button("Show solution") {
                    viewModel.revealSolution()
                }
                if !viewModel.showSolutionIDs.isEmpty {
                    Text(viewModel.showSolutionIDs.map(String.init).joined(separator: " → "))
                        .font(.footnote.monospaced())
                }
                Button("Highlight hint") {
                    viewModel.showHint()
                }
            }
            Section("Validation") {
                Button("Validate all levels") {
                    validation = validateAll()
                }
                if !validation.isEmpty {
                    Text(validation)
                        .font(.footnote.monospaced())
                }
            }
        }
        .navigationTitle("Developer")
    }

    private func validateAll() -> String {
        var failures: [Int] = []
        for level in services.catalog.levels {
            if LevelSolver.solve(level: level) == nil {
                failures.append(level.id)
            }
        }
        if failures.isEmpty {
            return "All \(services.catalog.levels.count) levels solvable."
        }
        return "Unsolvable: \(failures.map(String.init).joined(separator: ", "))"
    }
}
#endif
