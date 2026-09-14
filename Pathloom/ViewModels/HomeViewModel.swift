import Foundation
import Observation

@MainActor
struct HomeViewModel {
    let services: AppServices

    init(services: AppServices) {
        self.services = services
    }

    private var progress: PlayerProgress { services.progress.progress }

    var totalLevels: Int { LevelLoader.totalLevels(in: services.catalog) }
    var completedCount: Int { progress.completedCount }
    var unlockedCount: Int { min(progress.highestUnlockedLevel, totalLevels) }
    var continueID: Int { services.continueLevelID() }
    var streak: Int { progress.streak }
    var fractionComplete: Double {
        Double(completedCount) / Double(max(totalLevels, 1))
    }

    var hasStartedGame: Bool {
        completedCount > 0 || progress.highestUnlockedLevel > 1
    }

    var continueTitle: String {
        hasStartedGame ? "Continue" : "Start Game"
    }

    var headline: String {
        hasStartedGame ? "Continue your journey" : "Ready to solve?"
    }

    var subheadline: String {
        if !hasStartedGame {
            return "Start your first puzzle"
        }
        if completedCount >= totalLevels {
            return "Every path is clear. Replay any level."
        }
        return "Level \(continueID) is waiting."
    }

    var continueAccessibilityLabel: String {
        if hasStartedGame {
            return "Continue to level \(continueID)"
        }
        return "Start game, level \(continueID)"
    }

    var continueLevelBestMoves: Int? {
        progress.best(for: continueID)
    }

    var continueLevelStars: Int? {
        progress.stars(for: continueID)
    }

    var isDailyCompleteToday: Bool {
        progress.dailyChallengeCompleted && progress.dailyChallengeDate == Self.todayStamp
    }

    var dailyLevel: Level {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = (day - 1) % max(services.catalog.levels.count, 1)
        return services.catalog.levels[index]
    }

    var dailyTitle: String { "Daily Weave" }

    private static var todayStamp: String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
