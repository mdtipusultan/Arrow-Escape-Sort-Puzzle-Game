import SwiftUI

struct LevelSelectView: View {
    @Environment(AppServices.self) private var services
    var onSelect: (Int) -> Void

    private let columns = [GridItem(.adaptive(minimum: 72, maximum: 92), spacing: 12)]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: PathloomSpacing.lg) {
                ForEach(sectionRanges, id: \.lowerBound) { range in
                    VStack(alignment: .leading, spacing: 12) {
                        Text("\(range.lowerBound)–\(range.upperBound - 1)")
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(PathloomPalette.mutedText)
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(Array(range), id: \.self) { id in
                                tile(for: id)
                            }
                        }
                    }
                }
            }
            .padding(PathloomSpacing.lg)
        }
        .background(PathloomPalette.background.ignoresSafeArea())
        .navigationTitle("Levels")
        .navigationBarTitleDisplayMode(.large)
    }

    private var sectionRanges: [Range<Int>] {
        stride(from: 1, through: AppConstants.totalLevels, by: 10).map { start in
            start..<(min(start + 10, AppConstants.totalLevels + 1))
        }
    }

    @ViewBuilder
    private func tile(for id: Int) -> some View {
        let progress = services.progress.progress
        let unlocked = progress.isUnlocked(id)
        let completed = progress.isCompleted(id)
        let current = progress.highestUnlockedLevel == id && !completed

        Button {
            guard unlocked else { return }
            services.audio.play(.buttonTap)
            onSelect(id)
        } label: {
            VStack(spacing: 4) {
                if !unlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14, weight: .semibold))
                } else if completed {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                }
                Text("\(id)")
                    .font(.system(.headline, design: .rounded).weight(.bold))
            }
            .foregroundStyle(unlocked ? PathloomPalette.text : PathloomPalette.mutedText)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 64)
            .background(
                RoundedRectangle(cornerRadius: PathloomRadius.medium, style: .continuous)
                    .fill(completed ? PathloomPalette.success.opacity(0.18) : PathloomPalette.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: PathloomRadius.medium, style: .continuous)
                    .stroke(current ? PathloomPalette.primary : .clear, lineWidth: 2)
            )
        }
        .disabled(!unlocked)
        .accessibilityLabel(label(id: id, unlocked: unlocked, completed: completed, current: current))
    }

    private func label(id: Int, unlocked: Bool, completed: Bool, current: Bool) -> String {
        if !unlocked { return "Level \(id), locked" }
        if completed { return "Level \(id), completed" }
        if current { return "Level \(id), current" }
        return "Level \(id)"
    }
}
