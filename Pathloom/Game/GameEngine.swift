import Foundation

struct GameSnapshot: Equatable, Sendable {
    var arrows: [Int: Arrow]
    var moveCount: Int
}

struct GameEngine: Equatable, Sendable {
    private(set) var level: Level
    private(set) var arrows: [Int: Arrow]
    private(set) var moveCount: Int
    private(set) var wastedTaps: Int
    private(set) var undoCount: Int
    private var undoStack: [GameSnapshot]

    var remainingArrows: [Arrow] {
        arrows.values.filter(\.isActive).sorted { $0.id < $1.id }
    }

    var remainingCount: Int { remainingArrows.count }

    var isCleared: Bool { remainingCount == 0 }

    init(level: Level) {
        self.level = level
        var mapped: [Int: Arrow] = [:]
        for data in level.arrows {
            mapped[data.id] = Arrow(from: data)
        }
        arrows = mapped
        moveCount = 0
        wastedTaps = 0
        undoCount = 0
        undoStack = []
    }

    func arrow(id: Int) -> Arrow? {
        arrows[id]
    }

    func occupancy() -> [GridPosition: Int] {
        var map: [GridPosition: Int] = [:]
        for arrow in remainingArrows {
            map[arrow.position] = arrow.id
        }
        return map
    }

    func pathCells(for arrowID: Int) -> [GridPosition] {
        guard let arrow = arrows[arrowID], arrow.isActive else { return [] }
        return PathCalculator.pathToEdge(
            from: arrow.position,
            direction: arrow.direction,
            gridSize: level.gridSize
        )
    }

    func blockingArrowID(for arrowID: Int) -> Int? {
        guard arrows[arrowID]?.isActive == true else { return nil }
        let occupied = occupancy()
        for cell in pathCells(for: arrowID) {
            if let blocker = occupied[cell] {
                return blocker
            }
        }
        return nil
    }

    func canEscape(_ arrowID: Int) -> Bool {
        guard let arrow = arrows[arrowID], arrow.isActive else { return false }
        return blockingArrowID(for: arrowID) == nil
    }

    func escapableArrowIDs() -> [Int] {
        remainingArrows.compactMap { canEscape($0.id) ? $0.id : nil }
    }

    /// Returns one currently valid arrow, preferring a solver-backed first move when possible.
    func hintArrowID() -> Int? {
        if let solution = LevelSolver.solve(level: snapshotAsLevel(), remaining: remainingArrows) {
            return solution.first
        }
        return escapableArrowIDs().first
    }

    mutating func attemptEscape(_ arrowID: Int) -> EscapeOutcome {
        guard let arrow = arrows[arrowID], arrow.isActive else { return .blocked }
        guard canEscape(arrowID) else {
            wastedTaps += 1
            return .blocked
        }

        undoStack.append(GameSnapshot(arrows: arrows, moveCount: moveCount))
        arrows[arrowID]?.isActive = false
        moveCount += 1
        let length = PathCalculator.stepsToEdge(
            from: arrow.position,
            direction: arrow.direction,
            gridSize: level.gridSize
        )
        return .escaped(pathLength: length)
    }

    mutating func reset() {
        self = GameEngine(level: level)
    }

    @discardableResult
    mutating func undo() -> Bool {
        guard let snapshot = undoStack.popLast() else { return false }
        arrows = snapshot.arrows
        moveCount = snapshot.moveCount
        undoCount += 1
        return true
    }

    var canUndo: Bool { !undoStack.isEmpty }

    var starRating: Int {
        StarRating.stars(parMoves: level.parMoves, wastedTaps: wastedTaps, undoCount: undoCount)
    }

    private func snapshotAsLevel() -> Level {
        let active = remainingArrows.map {
            ArrowData(id: $0.id, row: $0.position.row, column: $0.position.column, direction: $0.direction)
        }
        return Level(
            id: level.id,
            gridSize: level.gridSize,
            parMoves: level.parMoves,
            difficulty: level.difficulty,
            arrows: active,
            seed: level.seed,
            archetype: level.archetype,
            patternType: level.patternType,
            patternFamily: level.patternFamily,
            difficultyScore: level.difficultyScore,
            solutionDepth: level.solutionDepth,
            branchingFactor: level.branchingFactor,
            bottleneckCount: level.bottleneckCount,
            clusterCount: level.clusterCount
        )
    }
}
