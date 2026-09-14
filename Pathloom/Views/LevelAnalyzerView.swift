#if DEBUG
import SwiftUI

struct LevelAnalyzerView: View {
    let level: Level

    var body: some View {
        let analysis = LevelAnalyzer.analyze(level)
        Form {
            Section("Overview") {
                row("Pattern", displayName(analysis.pattern))
                row("Difficulty", String(format: "%.1f / 10", analysis.difficultyScore))
                row("Tier", analysis.difficultyTier.displayName)
                row("Status", analysis.passed ? "PASS" : analysis.issues.joined(separator: ", "))
            }
            Section("Board") {
                row("Arrows", "\(analysis.arrows)")
                row("Board", "\(analysis.gridSize) × \(analysis.gridSize)")
                row("Density", String(format: "%.2f", analysis.density))
            }
            Section("Solver") {
                row("Optimal Moves", "\(analysis.optimalMoves)")
                row("Solution Depth", "\(analysis.solutionDepth)")
                row("Initial Valid Moves", "\(analysis.initialValidMoves)")
                row("Search Nodes", "\(analysis.nodesExpanded)")
            }
            Section("Structure") {
                row("Branches", "\(analysis.branches)")
                row("Bottlenecks", "\(analysis.bottlenecks)")
                row("Clusters", "\(analysis.clusters)")
                row("Dependencies", "\(analysis.dependencyCount)")
            }
        }
        .navigationTitle("Level Analyzer")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(PathloomPalette.mutedText)
                .multilineTextAlignment(.trailing)
        }
    }

    private func displayName(_ raw: String) -> String {
        LevelArchetype(rawValue: raw)?.displayName ?? raw
    }
}
#endif
