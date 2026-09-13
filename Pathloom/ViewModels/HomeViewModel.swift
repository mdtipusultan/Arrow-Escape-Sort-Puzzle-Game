import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    let services: AppServices

    init(services: AppServices) {
        self.services = services
    }

    var completedCount: Int { services.progress.progress.completedCount }
    var totalCount: Int { max(services.catalog.levels.count, AppConstants.totalLevels) }
    var continueID: Int { services.continueLevelID() }
    var streak: Int { services.progress.progress.streak }

    var dailyTitle: String {
        "Daily Weave"
    }

    var dailyLevel: Level {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = (day - 1) % max(services.catalog.levels.count, 1)
        return services.catalog.levels[index]
    }
}
