import Foundation

enum MapNodeState: Equatable, Sendable {
    case locked
    case available
    case current
    case completed
}

enum MapProgressManager {
    static func playableLevelID(progress: PlayerProgress, totalLevels: Int) -> Int {
        let total = max(totalLevels, 1)
        let unlocked = min(max(progress.highestUnlockedLevel, 1), total)
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
            return min(pending, totalLevels)
        }
        return playableLevelID(progress: progress, totalLevels: totalLevels)
    }
}
