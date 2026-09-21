import Foundation

enum MapNodeState: Equatable, Sendable {
    case locked
    case available
    case current
    case completed
}

/// Journey-facing progress helpers backed by `PlayerProgress`.
/// This is not a second save system — it only derives map focus and node states.
enum MapProgressManager {
    static func lastCompletedLevel(progress: PlayerProgress) -> Int? {
        progress.completedLevels.max()
    }

    static func nextPlayableLevel(progress: PlayerProgress, totalLevels: Int) -> Int {
        min(max(progress.highestUnlockedLevel, 1), max(totalLevels, 1))
    }

    static func currentLevel(progress: PlayerProgress, totalLevels: Int) -> Int {
        playableLevelID(progress: progress, totalLevels: totalLevels)
    }

    static func playableLevelID(progress: PlayerProgress, totalLevels: Int) -> Int {
        let total = max(totalLevels, 1)
        let unlocked = nextPlayableLevel(progress: progress, totalLevels: total)
        for id in 1...unlocked where !progress.isCompleted(id) {
            return id
        }
        return unlocked
    }

    static func state(for levelID: Int, progress: PlayerProgress, currentID: Int) -> MapNodeState {
        if progress.isCompleted(levelID) { return .completed }
        if !progress.isUnlocked(levelID) { return .locked }
        if levelID == currentID { return .current }
        return .available
    }

    static func isMilestone(_ levelID: Int) -> Bool {
        MapLayoutEngine.isMilestone(levelID)
    }

    static func focusLevelID(
        progress: PlayerProgress,
        totalLevels: Int,
        pendingReveal: Int?
    ) -> Int {
        if let pending = pendingReveal, pending >= 1 {
            return min(pending, max(totalLevels, 1))
        }
        return playableLevelID(progress: progress, totalLevels: totalLevels)
    }
}
