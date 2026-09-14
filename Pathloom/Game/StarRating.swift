import Foundation

enum StarRating {
    /// Successful escapes always equal the arrow count. Stars reward clean play:
    /// few blocked taps and undos relative to par.
    static func stars(parMoves: Int, wastedTaps: Int, undoCount: Int) -> Int {
        let waste = max(0, wastedTaps) + max(0, undoCount)
        if waste <= 1 { return 3 }
        let twoStarLimit = max(3, (parMoves + 3) / 4)
        if waste <= twoStarLimit { return 2 }
        return 1
    }

    static func label(_ count: Int) -> String {
        String(repeating: "★", count: max(1, min(3, count)))
            + String(repeating: "☆", count: max(0, 3 - max(1, min(3, count))))
    }
}
