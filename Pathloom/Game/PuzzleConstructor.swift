import Foundation

struct ConstructedPuzzle: Sendable {
    var level: Level
    var solution: [Int]
}

enum PuzzleConstructor {
    static func build(spec: LevelSpec, previous: [Level] = []) -> Level? {
        for attempt in 0..<28 {
            var rng = SplitMix64(seed: UInt64(bitPattern: Int64(spec.seed &+ attempt &* 9_917)))
            guard let puzzle = weave(spec: spec, rng: &rng) else { continue }
            guard LevelSolver.sequenceClears(puzzle.solution, level: puzzle.level) else { continue }
            if LevelGraph.hasOverlaps(puzzle.level) || LevelGraph.hasOutOfBounds(puzzle.level) { continue }
            let analysis = LevelAnalyzer.analyze(puzzle.level)
            let fingerprint = LevelSimilarity.fingerprint(puzzle.level, analysis: analysis)
            let prior = previous.suffix(12).map { LevelSimilarity.fingerprint($0) }
            if prior.contains(where: { LevelSimilarity.tooSimilar(fingerprint, $0) }) {
                continue
            }
            if spec.id >= 41 && analysis.solutionDepth < max(6, spec.targetDepth.lowerBound - 2) { continue }
            if spec.id >= 61 && analysis.initialValidMoves > 3 { continue }
            if spec.id >= 80 && analysis.solutionDepth < 8 { continue }
            return PatternEngine.stamp(puzzle.level, spec: spec, analysis: analysis)
        }
        return nil
    }

    private struct Recipe {
        var clusters: Int
        var bottleneckStride: Int
        var crossBias: Bool
        var bridge: Bool
        var layerSpread: Int
    }

    private static func recipe(for spec: LevelSpec) -> Recipe {
        switch spec.pattern.family {
        case .chain:
            return Recipe(clusters: 1, bottleneckStride: 99, crossBias: spec.pattern == .zigzagChain || spec.pattern == .alternatingDirectionChain, bridge: false, layerSpread: 1)
        case .branching:
            return Recipe(clusters: 1, bottleneckStride: max(3, spec.arrowCount / 4), crossBias: false, bridge: false, layerSpread: spec.pattern == .tripleBranch || spec.pattern == .wideBranch ? 3 : 2)
        case .bottleneck:
            return Recipe(clusters: 1, bottleneckStride: max(3, spec.arrowCount / 5), crossBias: false, bridge: false, layerSpread: spec.pattern == .multiBottleneck || spec.pattern == .doubleBottleneck ? 3 : 2)
        case .cross:
            return Recipe(clusters: 1, bottleneckStride: max(4, spec.arrowCount / 4), crossBias: true, bridge: false, layerSpread: 2)
        case .cluster:
            return Recipe(clusters: spec.pattern == .tripleCluster ? 3 : 2, bottleneckStride: 6, crossBias: false, bridge: true, layerSpread: 2)
        case .advanced:
            return Recipe(
                clusters: spec.pattern == .multiBottleneck ? 1 : 2,
                bottleneckStride: spec.pattern == .deepLock ? 99 : 4,
                crossBias: spec.pattern == .dependencyWeb,
                bridge: spec.pattern == .bridgePattern || spec.pattern == .multiStageUnlock,
                layerSpread: spec.pattern == .deepLock ? 1 : 2
            )
        case .hybrid:
            return Recipe(clusters: 3, bottleneckStride: 4, crossBias: true, bridge: true, layerSpread: 3)
        }
    }

    private static func weave(spec: LevelSpec, rng: inout SplitMix64) -> ConstructedPuzzle? {
        let grid = min(max(spec.gridSize, 4), 11)
        let count = min(max(spec.arrowCount, 2), min(45, grid * grid - 2))
        let plan = recipe(for: spec)
        var board = WorkingBoard(gridSize: grid)
        let regions = Region.pack(count: max(1, plan.clusters), rng: &rng)
        guard let seed = board.placeSeed(in: regions.last ?? .center, rng: &rng) else { return nil }

        var solution: [Int] = [seed]
        var regionIndex = regions.count - 1
        var sinceBottleneck = 0
        let desiredInitial = clampedInitial(spec.targetInitial, rng: &rng, id: spec.id)

        let coreCount = max(1, count - max(0, desiredInitial - 1))
        while board.arrows.count < coreCount {
            let region = regions[max(regionIndex, 0)]
            let free = board.freeIDs()
            guard !free.isEmpty else { return nil }

            let layer = min(plan.layerSpread, max(1, free.count))
            let shouldBottleneck = plan.bottleneckStride < 90 && (sinceBottleneck >= plan.bottleneckStride || board.arrows.count % plan.bottleneckStride == 0)
            let targets: [Int]
            if shouldBottleneck {
                targets = free
                sinceBottleneck = 0
            } else {
                targets = Array(free.suffix(layer))
                sinceBottleneck += 1
            }

            let prefer: Direction? = plan.crossBias ? board.arrows[targets[0]]?.direction.rotated : nil
            if let placed = board.placeBlocker(
                blocking: targets,
                also: Array(board.arrows.keys.filter { !targets.contains($0) }.prefix(4)),
                region: region,
                preferred: prefer,
                rng: &rng
            ) {
                solution.insert(placed, at: 0)
            } else if let placed = board.placeBlocker(
                blocking: [targets[0]],
                also: [],
                region: Region.any,
                preferred: Optional<Direction>.none,
                rng: &rng
            ) {
                solution.insert(placed, at: 0)
            } else {
                return nil
            }

            if plan.bridge, plan.clusters > 1, board.arrows.count % max(3, coreCount / plan.clusters) == 0 {
                regionIndex = max(regionIndex - 1, 0)
            }
        }

        while board.arrows.count < count {
            let extras = board.placeSideBranch(region: regions.first ?? .center, rng: &rng)
            if let placed = extras {
                solution.insert(placed, at: 0)
            } else {
                break
            }
        }

        guard board.arrows.count >= max(2, spec.arrowCount - 3) else { return nil }
        let arrows = board.reindexed()
        let remapped = remap(solution, from: board.arrows, to: arrows)
        let level = Level(
            id: spec.id,
            gridSize: grid,
            parMoves: arrows.count,
            difficulty: spec.difficulty,
            arrows: arrows,
            seed: spec.seed,
            archetype: spec.pattern.rawValue,
            patternType: spec.pattern.rawValue,
            patternFamily: spec.pattern.family.rawValue
        )
        return ConstructedPuzzle(level: level, solution: remapped)
    }

    private static func clampedInitial(_ range: ClosedRange<Int>, rng: inout SplitMix64, id: Int) -> Int {
        let lo = max(1, range.lowerBound)
        let hi = max(lo, range.upperBound)
        if id >= 21 && id % 3 == 0 { return lo }
        return lo + Int(rng.next() % UInt64(hi - lo + 1))
    }

    private static func remap(_ solution: [Int], from original: [Int: ArrowData], to arrows: [ArrowData]) -> [Int] {
        var newByCell: [String: Int] = [:]
        for arrow in arrows {
            newByCell["\(arrow.row),\(arrow.column),\(arrow.direction.rawValue)"] = arrow.id
        }
        return solution.compactMap { old in
            guard let arrow = original[old] else { return nil }
            let key = "\(arrow.row),\(arrow.column),\(arrow.direction.rawValue)"
            return newByCell[key]
        }
    }
}

private struct WorkingBoard {
    let gridSize: Int
    var occupied: [GridPosition: Int] = [:]
    var arrows: [Int: ArrowData] = [:]
    private var nextID = 1

    init(gridSize: Int) {
        self.gridSize = gridSize
    }

    mutating func placeSeed(in region: Region, rng: inout SplitMix64) -> Int? {
        let cells = region.cells(gridSize: gridSize).shuffled(using: &rng).filter { occupied[$0] == nil }
        for cell in cells.prefix(24) {
            for direction in Direction.allCases.shuffled(using: &rng) {
                if pathClear(from: cell, direction: direction) && PathCalculator.pathToEdge(from: cell, direction: direction, gridSize: gridSize).count >= 2 {
                    return occupy(cell, direction)
                }
            }
        }
        for cell in cells {
            for direction in Direction.allCases.shuffled(using: &rng) where pathClear(from: cell, direction: direction) {
                return occupy(cell, direction)
            }
        }
        return nil
    }

    mutating func placeBlocker(
        blocking: [Int],
        also: [Int],
        region: Region,
        preferred: Direction?,
        rng: inout SplitMix64
    ) -> Int? {
        var scored: [(Int, ArrowData)] = []
        let targets = blocking + also
        var cells: [GridPosition] = []
        for id in blocking {
            guard let arrow = arrows[id] else { continue }
            for cell in path(of: arrow) where occupied[cell] == nil && region.contains(cell, gridSize: gridSize) {
                cells.append(cell)
            }
        }
        if cells.isEmpty {
            for id in blocking {
                guard let arrow = arrows[id] else { continue }
                cells.append(contentsOf: path(of: arrow).filter { occupied[$0] == nil })
            }
        }
        cells = Array(Set(cells)).shuffled(using: &rng)
        for cell in cells.prefix(28) {
            var directions = Direction.allCases.shuffled(using: &rng)
            if let preferred {
                directions.removeAll { $0 == preferred }
                directions.insert(preferred, at: 0)
            }
            for direction in directions where pathClear(from: cell, direction: direction) {
                let data = ArrowData(id: 0, row: cell.row, column: cell.column, direction: direction)
                let hits = targets.filter { id in
                    guard let arrow = arrows[id] else { return false }
                    return path(of: arrow).contains(cell)
                }.count
                let length = PathCalculator.pathToEdge(from: cell, direction: direction, gridSize: gridSize).count
                scored.append((hits * 10 + length, data))
            }
        }
        scored.sort { $0.0 > $1.0 }
        guard let pick = scored.first?.1 else { return nil }
        return occupy(GridPosition(row: pick.row, column: pick.column), pick.direction)
    }

    mutating func placeSideBranch(region: Region, rng: inout SplitMix64) -> Int? {
        let locked = arrows.keys.filter { id in
            guard let arrow = arrows[id] else { return false }
            return !canEscape(arrow)
        }
        if let blocker = placeBlocker(blocking: Array(locked.prefix(3)), also: [], region: region, preferred: nil, rng: &rng) {
            return blocker
        }
        return placeSeed(in: region, rng: &rng)
    }

    func freeIDs() -> [Int] {
        arrows.values.filter(canEscape).map(\.id).sorted()
    }

    func reindexed() -> [ArrowData] {
        arrows.values.sorted { $0.id < $1.id }.enumerated().map { index, arrow in
            ArrowData(id: index + 1, row: arrow.row, column: arrow.column, direction: arrow.direction)
        }
    }

    private mutating func occupy(_ cell: GridPosition, _ direction: Direction) -> Int? {
        guard occupied[cell] == nil else { return nil }
        let id = nextID
        nextID += 1
        let data = ArrowData(id: id, row: cell.row, column: cell.column, direction: direction)
        arrows[id] = data
        occupied[cell] = id
        return id
    }

    private func path(of arrow: ArrowData) -> [GridPosition] {
        PathCalculator.pathToEdge(from: arrow.position, direction: arrow.direction, gridSize: gridSize)
    }

    private func pathClear(from cell: GridPosition, direction: Direction) -> Bool {
        PathCalculator.pathToEdge(from: cell, direction: direction, gridSize: gridSize).allSatisfy { occupied[$0] == nil }
    }

    private func canEscape(_ arrow: ArrowData) -> Bool {
        path(of: arrow).allSatisfy { occupied[$0] == nil }
    }
}

private enum Region: CaseIterable {
    case topLeft, topRight, bottomLeft, bottomRight, center, any

    static func pack(count: Int, rng: inout SplitMix64) -> [Region] {
        let pool: [Region] = [.bottomLeft, .bottomRight, .topLeft, .topRight, .center]
        let shuffled = pool.shuffled(using: &rng)
        if count <= 1 { return [.center] }
        return Array(shuffled.prefix(count))
    }

    func contains(_ cell: GridPosition, gridSize: Int) -> Bool {
        switch self {
        case .any: return true
        case .center:
            let mid = gridSize / 2
            return abs(cell.row - mid) <= gridSize / 3 && abs(cell.column - mid) <= gridSize / 3
        case .topLeft: return cell.row < gridSize / 2 && cell.column < (gridSize + 1) / 2
        case .topRight: return cell.row < gridSize / 2 && cell.column >= gridSize / 2
        case .bottomLeft: return cell.row >= gridSize / 2 && cell.column < (gridSize + 1) / 2
        case .bottomRight: return cell.row >= gridSize / 2 && cell.column >= gridSize / 2
        }
    }

    func cells(gridSize: Int) -> [GridPosition] {
        (0..<gridSize).flatMap { row in
            (0..<gridSize).compactMap { column in
                let cell = GridPosition(row: row, column: column)
                return contains(cell, gridSize: gridSize) ? cell : nil
            }
        }
    }
}

private extension Direction {
    var rotated: Direction {
        switch self {
        case .up: .right
        case .right: .down
        case .down: .left
        case .left: .up
        }
    }
}
