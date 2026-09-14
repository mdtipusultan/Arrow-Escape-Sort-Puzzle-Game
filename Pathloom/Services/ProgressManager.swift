import Foundation
import Observation

struct PlayerProgress: Codable, Equatable, Sendable {
    var highestUnlockedLevel: Int
    var completedLevels: Set<Int>
    var bestMoves: [Int: Int]
    var bestStars: [Int: Int]
    var dailyChallengeDate: String?
    var dailyChallengeCompleted: Bool
    var streak: Int

    static let fresh = PlayerProgress(
        highestUnlockedLevel: 1,
        completedLevels: [],
        bestMoves: [:],
        bestStars: [:],
        dailyChallengeDate: nil,
        dailyChallengeCompleted: false,
        streak: 0
    )

    var completedCount: Int { completedLevels.count }

    func isUnlocked(_ levelID: Int) -> Bool {
        levelID <= highestUnlockedLevel
    }

    func isCompleted(_ levelID: Int) -> Bool {
        completedLevels.contains(levelID)
    }

    func best(for levelID: Int) -> Int? {
        bestMoves[levelID]
    }

    func stars(for levelID: Int) -> Int? {
        bestStars[levelID]
    }

    enum CodingKeys: String, CodingKey {
        case highestUnlockedLevel, completedLevels, bestMoves, bestStars
        case dailyChallengeDate, dailyChallengeCompleted, streak
    }

    init(
        highestUnlockedLevel: Int,
        completedLevels: Set<Int>,
        bestMoves: [Int: Int],
        bestStars: [Int: Int] = [:],
        dailyChallengeDate: String?,
        dailyChallengeCompleted: Bool,
        streak: Int
    ) {
        self.highestUnlockedLevel = highestUnlockedLevel
        self.completedLevels = completedLevels
        self.bestMoves = bestMoves
        self.bestStars = bestStars
        self.dailyChallengeDate = dailyChallengeDate
        self.dailyChallengeCompleted = dailyChallengeCompleted
        self.streak = streak
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        highestUnlockedLevel = try container.decode(Int.self, forKey: .highestUnlockedLevel)
        completedLevels = try container.decode(Set<Int>.self, forKey: .completedLevels)
        bestMoves = try container.decode([Int: Int].self, forKey: .bestMoves)
        bestStars = try container.decodeIfPresent([Int: Int].self, forKey: .bestStars) ?? [:]
        dailyChallengeDate = try container.decodeIfPresent(String.self, forKey: .dailyChallengeDate)
        dailyChallengeCompleted = try container.decodeIfPresent(Bool.self, forKey: .dailyChallengeCompleted) ?? false
        streak = try container.decodeIfPresent(Int.self, forKey: .streak) ?? 0
    }
}

protocol ProgressStoring: AnyObject {
    var progress: PlayerProgress { get }
    func recordCompletion(levelID: Int, moves: Int, totalLevels: Int, stars: Int)
    func reset()
}

@MainActor
@Observable
final class ProgressManager: ProgressStoring {
    private let defaults: UserDefaults
    private let key = "pathloom.progress.v1"

    private(set) var progress: PlayerProgress

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode(PlayerProgress.self, from: data),
           decoded.highestUnlockedLevel >= 1 {
            progress = decoded
        } else {
            progress = .fresh
            persist()
        }
    }

    func recordCompletion(levelID: Int, moves: Int, totalLevels: Int, stars: Int = 1) {
        progress.completedLevels.insert(levelID)
        if let existing = progress.bestMoves[levelID] {
            progress.bestMoves[levelID] = min(existing, moves)
        } else {
            progress.bestMoves[levelID] = moves
        }
        if let existing = progress.bestStars[levelID] {
            progress.bestStars[levelID] = max(existing, stars)
        } else {
            progress.bestStars[levelID] = stars
        }
        let next = min(levelID + 1, totalLevels)
        progress.highestUnlockedLevel = max(progress.highestUnlockedLevel, next)
        updateStreak()
        persist()
    }

    private func updateStreak() {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        if progress.dailyChallengeDate == today {
            return
        }
        if let previous = progress.dailyChallengeDate,
           let previousDate = formatter.date(from: previous),
           let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()),
           formatter.string(from: previousDate) == formatter.string(from: yesterday) {
            progress.streak += 1
        } else {
            progress.streak = 1
        }
        progress.dailyChallengeDate = today
        progress.dailyChallengeCompleted = true
    }

    func reset() {
        progress = .fresh
        persist()
    }

    #if DEBUG
    func unlockAll(totalLevels: Int) {
        progress.highestUnlockedLevel = totalLevels
        persist()
    }

    func jumpTo(levelID: Int, totalLevels: Int) {
        progress.highestUnlockedLevel = min(max(levelID, 1), totalLevels)
        persist()
    }
    #endif

    private func persist() {
        if let data = try? JSONEncoder().encode(progress) {
            defaults.set(data, forKey: key)
        }
    }
}
