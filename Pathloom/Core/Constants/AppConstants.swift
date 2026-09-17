import Foundation

enum AppConstants {
    static let gameName = "Pathloom"
    static let tagline = "Think ahead. Clear the way."
    static let totalLevels = 200
    static let splashDuration: TimeInterval = 1.35
    static let minimumTouchTarget: CGFloat = 44

    enum Animation {
        static let blockedShake: TimeInterval = 0.18
        static let moveMin: TimeInterval = 0.32
        static let moveMax: TimeInterval = 0.72
        static let fadeExit: TimeInterval = 0.12
        static let completeHold: TimeInterval = 0.45
        static let springResponse: Double = 0.42
        static let springDamping: Double = 0.78
    }

    enum Board {
        static let widthScreenFactor: CGFloat = 0.92
        static let maximumWidth: CGFloat = 560
        static let cornerRadiusFactor: CGFloat = 0.08
        static let paddingFactor: CGFloat = 0.06
        static let cellGapFactor: CGFloat = 0.08
    }

    enum Audio {
        static let musicVolume: Float = 0.12
        static let effectsVolume: Float = 0.85
    }
}
