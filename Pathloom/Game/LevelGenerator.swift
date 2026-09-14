import Foundation

struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

struct LevelSpec: Sendable {
    var id: Int
    var difficulty: Difficulty
    var archetype: LevelArchetype
    var gridSize: Int
    var arrowCount: Int
    var targetDepth: ClosedRange<Int>
    var targetInitial: ClosedRange<Int>
    var minScore: Double
    var seed: Int
}

enum BoardFormation: CaseIterable {
    case open, lShape, tShape, cross, staircase, corner, hollow, uShape, zigzag, asymmetric, split, denseCenter, denseEdge, offset
}

enum LevelGenerator {
    private struct Placed {
        var id: Int
        var row: Int
        var column: Int
        var direction: Direction

        var data: ArrowData {
            ArrowData(id: id, row: row, column: column, direction: direction)
        }

        var position: GridPosition { GridPosition(row: row, column: column) }
    }

    private struct Candidate {
        var row: Int
        var column: Int
        var direction: Direction
        var blockedIDs: [Int]
        var pathLength: Int
    }

    static func generate(spec: LevelSpec, previous: [Level] = []) -> Level? {
        if let crafted = handcrafted(id: spec.id) {
            return finalize(crafted, spec: spec) ?? spiralGuarantee(spec: spec)
        }

        var rng = SplitMix64(seed: UInt64(bitPattern: Int64(spec.seed)))
        let maxAttempts = 48
        let previousPrints = previous.suffix(8).map { LevelSimilarity.fingerprint($0) }

        for attempt in 0..<maxAttempts {
            var attemptRNG = SplitMix64(seed: UInt64(bitPattern: Int64(spec.seed &+ attempt &* 131)) &+ rng.next())
            let formation = attempt % 5 == 4
                ? BoardFormation.open
                : formation(for: spec.archetype, attempt: attempt, rng: &attemptRNG)
            guard var arrows = layout(spec: spec, formation: formation, rng: &attemptRNG) else { continue }
            arrows = Array(arrows.prefix(spec.arrowCount))
            guard arrows.count == spec.arrowCount else { continue }

            let draft = Level(
                id: spec.id,
                gridSize: spec.gridSize,
                parMoves: spec.arrowCount,
                difficulty: spec.difficulty,
                arrows: arrows.map(\.data),
                seed: spec.seed + attempt,
                archetype: spec.archetype.rawValue
            )
            guard let finished = finalize(draft, spec: spec) else { continue }
            let analysis = LevelAnalyzer.analyze(finished)
            if !analysis.passed { continue }

            let relax = attempt > 50
            if !relax {
                if analysis.solutionDepth < spec.targetDepth.lowerBound { continue }
                if analysis.solutionDepth > spec.targetDepth.upperBound + 3 { continue }
                if analysis.initialValidMoves < spec.targetInitial.lowerBound { continue }
                if analysis.initialValidMoves > spec.targetInitial.upperBound + 1 { continue }
                if analysis.difficultyScore + 1.6 < spec.minScore { continue }
                if analysis.arrows > 4 && analysis.dependencyCount == 0 { continue }
                if spec.id >= 15 {
                    let used = LevelGraph.directionHistogram(finished).values.filter { $0 > 0 }.count
                    if used < 3 { continue }
                }
            } else {
                if analysis.solutionDepth < max(1, spec.targetDepth.lowerBound - 2) { continue }
                if analysis.initialValidMoves < 1 { continue }
                if spec.id >= 15 {
                    let used = LevelGraph.directionHistogram(finished).values.filter { $0 > 0 }.count
                    if used < 3 { continue }
                }
            }

            let fingerprint = LevelSimilarity.fingerprint(finished, analysis: analysis)
            if previousPrints.contains(where: { LevelSimilarity.tooSimilar(fingerprint, $0) }) {
                continue
            }
            return finished
        }
        return finalize(spiralGuarantee(spec: spec), spec: spec) ?? spiralGuarantee(spec: spec)
    }

    static func guaranteedLevel(spec: LevelSpec) -> Level {
        spiralGuarantee(spec: spec)
    }

    private static func spiralGuarantee(spec: LevelSpec) -> Level {
        let grid = max(spec.gridSize, 3)
        let count = min(max(spec.arrowCount, 1), grid * grid - 1)
        let cells = spiralCells(grid: grid).map { transform($0, mode: spec.seed % 4, grid: grid) }
        var arrows: [ArrowData] = []
        for (index, cell) in cells.prefix(count).enumerated() {
            let direction: Direction
            if index == 0 {
                direction = nearestEdge(from: cell, gridSize: grid)
            } else {
                let previous = cells[index - 1]
                if cell.row == previous.row {
                    direction = cell.column < previous.column ? .right : .left
                } else if cell.column == previous.column {
                    direction = cell.row < previous.row ? .down : .up
                } else {
                    direction = nearestEdge(from: cell, gridSize: grid)
                }
            }
            arrows.append(ArrowData(id: index + 1, row: cell.row, column: cell.column, direction: direction))
        }
        return Level(
            id: spec.id,
            gridSize: grid,
            parMoves: arrows.count,
            difficulty: spec.difficulty,
            arrows: arrows,
            seed: spec.seed,
            archetype: spec.archetype.rawValue
        )
    }

    private static func spiralCells(grid: Int) -> [GridPosition] {
        var cells: [GridPosition] = []
        var top = 0
        var bottom = grid - 1
        var left = 0
        var right = grid - 1
        while top <= bottom && left <= right {
            for column in left...right {
                cells.append(GridPosition(row: top, column: column))
            }
            top += 1
            if top > bottom { break }
            for row in top...bottom {
                cells.append(GridPosition(row: row, column: right))
            }
            right -= 1
            if left > right { break }
            for column in stride(from: right, through: left, by: -1) {
                cells.append(GridPosition(row: bottom, column: column))
            }
            bottom -= 1
            if top > bottom { break }
            for row in stride(from: bottom, through: top, by: -1) {
                cells.append(GridPosition(row: row, column: left))
            }
            left += 1
        }
        return cells
    }

    private static func transform(_ cell: GridPosition, mode: Int, grid: Int) -> GridPosition {
        let last = grid - 1
        switch mode {
        case 1: return GridPosition(row: cell.column, column: cell.row)
        case 2: return GridPosition(row: last - cell.row, column: cell.column)
        case 3: return GridPosition(row: cell.row, column: last - cell.column)
        default: return cell
        }
    }

    private static func nearestEdge(from cell: GridPosition, gridSize: Int) -> Direction {
        let distances: [(Direction, Int)] = [
            (.up, cell.row),
            (.left, cell.column),
            (.down, gridSize - 1 - cell.row),
            (.right, gridSize - 1 - cell.column)
        ]
        return distances.min(by: { $0.1 < $1.1 })?.0 ?? .up
    }

    private static func finalize(_ level: Level, spec: LevelSpec) -> Level? {
        guard let report = LevelSolver.report(level: level) else { return nil }
        let analysis = LevelAnalyzer.analyze(level)
        return Level(
            id: spec.id,
            gridSize: level.gridSize,
            parMoves: report.optimalMoves,
            difficulty: spec.difficulty,
            arrows: level.arrows,
            seed: level.seed,
            archetype: level.archetype ?? spec.archetype.rawValue,
            difficultyScore: (analysis.difficultyScore * 10).rounded() / 10,
            solutionDepth: report.solutionDepth
        )
    }

    private static func layout(spec: LevelSpec, formation: BoardFormation, rng: inout SplitMix64) -> [Placed]? {
        let clustered: [Placed]?
        switch spec.archetype {
        case .doubleCluster, .splitBoard, .bridge:
            clustered = clusteredLayout(spec: spec, clusters: 2, rng: &rng)
        case .tripleCluster, .multiCluster:
            clustered = clusteredLayout(spec: spec, clusters: spec.gridSize >= 6 ? 3 : 2, rng: &rng)
        default:
            clustered = nil
        }
        if let clustered, clustered.count == spec.arrowCount {
            return clustered
        }
        var allowed = formationCells(formation, gridSize: spec.gridSize)
        if allowed.count < spec.arrowCount + 1 {
            allowed = formationCells(.open, gridSize: spec.gridSize)
        }
        if let placed = reversePlace(count: spec.arrowCount, gridSize: spec.gridSize, allowed: allowed, archetype: spec.archetype, startID: 1, rng: &rng),
           placed.count == spec.arrowCount {
            return placed
        }
        return reversePlace(
            count: spec.arrowCount,
            gridSize: spec.gridSize,
            allowed: formationCells(.open, gridSize: spec.gridSize),
            archetype: spec.archetype,
            startID: 1,
            rng: &rng
        )
    }

    private static func clusteredLayout(spec: LevelSpec, clusters: Int, rng: inout SplitMix64) -> [Placed]? {
        let g = spec.gridSize
        let mid = g / 2
        var regions: [Set<GridPosition>] = []
        if clusters >= 3 && g >= 6 {
            regions = [
                region(gridSize: g) { $0 < mid && $1 < mid },
                region(gridSize: g) { $0 < mid && $1 > mid },
                region(gridSize: g) { $0 > mid && $1 >= 0 }
            ]
        } else {
            regions = [
                region(gridSize: g) { _, c in c < mid - (g > 5 ? 1 : 0) },
                region(gridSize: g) { _, c in c > mid + (g > 5 ? 1 : 0) }
            ]
        }
        regions = regions.filter { $0.count >= 3 }
        guard regions.count >= 2 else {
            return reversePlace(count: spec.arrowCount, gridSize: g, allowed: formationCells(.split, gridSize: g), archetype: spec.archetype, startID: 1, rng: &rng)
        }

        let bridgeSlots = spec.archetype == .bridge || spec.archetype == .multiCluster ? 1 : 0
        let remaining = spec.arrowCount - bridgeSlots
        var counts = Array(repeating: remaining / regions.count, count: regions.count)
        counts[0] += remaining % regions.count
        for i in counts.indices where counts[i] < 2 {
            counts[i] = 2
        }
        while counts.reduce(0, +) > remaining {
            if let idx = counts.indices.max(by: { counts[$0] < counts[$1] }), counts[idx] > 2 {
                counts[idx] -= 1
            } else {
                break
            }
        }

        var placed: [Placed] = []
        var nextID = 1
        for (index, cells) in regions.enumerated() {
            guard index < counts.count else { break }
            guard let group = reversePlace(count: counts[index], gridSize: g, allowed: cells, archetype: .mixedDirection, startID: nextID, rng: &rng, expandToOpen: false) else {
                return nil
            }
            placed.append(contentsOf: group)
            nextID += group.count
        }

        if bridgeSlots == 1 {
            if let bridge = makeBridge(into: &placed, gridSize: g, allowed: formationCells(.open, gridSize: g), id: nextID, rng: &rng) {
                placed.append(bridge)
            } else if placed.count < spec.arrowCount {
                let leftover = spec.arrowCount - placed.count
                if let extra = reversePlace(count: leftover, gridSize: g, allowed: formationCells(.open, gridSize: g), archetype: .mixedDirection, startID: nextID, rng: &rng, existing: placed) {
                    placed.append(contentsOf: extra)
                }
            }
        }

        if placed.count > spec.arrowCount {
            placed = Array(placed.prefix(spec.arrowCount))
        }
        if placed.count < spec.arrowCount {
            let missing = spec.arrowCount - placed.count
            if let extra = reversePlace(count: missing, gridSize: g, allowed: formationCells(.open, gridSize: g), archetype: spec.archetype, startID: (placed.map(\.id).max() ?? 0) + 1, rng: &rng, existing: placed) {
                placed.append(contentsOf: extra)
            }
        }
        return placed.count == spec.arrowCount ? placed : nil
    }

    private static func makeBridge(into placed: inout [Placed], gridSize: Int, allowed: Set<GridPosition>, id: Int, rng: inout SplitMix64) -> Placed? {
        let occupied = Dictionary(placed.map { ($0.position, $0) }, uniquingKeysWith: { _, last in last })
        var best: Candidate?
        for cell in allowed where occupied[cell] == nil {
            for direction in shuffledDirections(&rng) {
                let path = PathCalculator.pathToEdge(from: cell, direction: direction, gridSize: gridSize)
                if path.contains(where: { occupied[$0] != nil }) { continue }
                let blocked = occupied.values.filter { existing in
                    PathCalculator.pathToEdge(from: existing.position, direction: existing.direction, gridSize: gridSize).contains(cell)
                }
                if blocked.count >= 2 {
                    let candidate = Candidate(row: cell.row, column: cell.column, direction: direction, blockedIDs: blocked.map(\.id), pathLength: path.count)
                    if candidate.blockedIDs.count > (best?.blockedIDs.count ?? 0) {
                        best = candidate
                    }
                }
            }
        }
        guard let pick = best else { return nil }
        return Placed(id: id, row: pick.row, column: pick.column, direction: pick.direction)
    }

    private static func reversePlace(
        count: Int,
        gridSize: Int,
        allowed: Set<GridPosition>,
        archetype: LevelArchetype,
        startID: Int,
        rng: inout SplitMix64,
        existing: [Placed] = [],
        expandToOpen: Bool = true
    ) -> [Placed]? {
        var placed = existing
        var nextID = startID
        let target = existing.count + count
        if placed.isEmpty {
            guard let first = placeSeed(allowed: allowed, gridSize: gridSize, id: nextID, rng: &rng) else { return nil }
            placed.append(first)
            nextID += 1
        }

        while placed.count < target {
            let occupied = Dictionary(placed.map { ($0.position, $0) }, uniquingKeysWith: { _, last in last })
            var searchSpace = allowed
            var candidates = collectCandidates(occupied: occupied, allowed: searchSpace, gridSize: gridSize, rng: &rng)
            if candidates.isEmpty && expandToOpen {
                searchSpace = formationCells(.open, gridSize: gridSize)
                candidates = collectCandidates(occupied: occupied, allowed: searchSpace, gridSize: gridSize, rng: &rng)
            }
            let decoyChance = decoyProbability(archetype)
            let preferDecoy = Double(rng.next() % 1000) / 1000.0 < decoyChance && placed.count + 1 < target

            let chosen: Candidate?
            if preferDecoy {
                chosen = decoyCandidate(occupied: occupied, allowed: searchSpace, gridSize: gridSize, rng: &rng)
                    ?? pickCandidate(candidates, placed: placed, archetype: archetype, rng: &rng)
            } else {
                chosen = pickCandidate(candidates, placed: placed, archetype: archetype, rng: &rng)
                    ?? decoyCandidate(occupied: occupied, allowed: searchSpace, gridSize: gridSize, rng: &rng)
            }
            guard let pick = chosen else { return nil }
            placed.append(Placed(id: nextID, row: pick.row, column: pick.column, direction: pick.direction))
            nextID += 1
        }

        // Reverse construction places last-to-move first. Reassign IDs in play order
        // so later-placed arrows (first moves) keep stable increasing IDs.
        let playOrder = Array(placed.suffix(count).reversed())
        return playOrder.enumerated().map { index, arrow in
            Placed(id: startID + index, row: arrow.row, column: arrow.column, direction: arrow.direction)
        }
    }

    private static func placeSeed(allowed: Set<GridPosition>, gridSize: Int, id: Int, rng: inout SplitMix64) -> Placed? {
        let last = gridSize - 1
        let interior = allowed.filter { $0.row > 0 && $0.column > 0 && $0.row < last && $0.column < last }
        let pool = interior.isEmpty ? Array(allowed) : Array(interior)
        guard !pool.isEmpty else { return nil }
        for _ in 0..<24 {
            let cell = pool[Int(rng.next() % UInt64(pool.count))]
            let dirs = shuffledDirections(&rng)
            var best: (Direction, Int)?
            for direction in dirs {
                let path = PathCalculator.pathToEdge(from: cell, direction: direction, gridSize: gridSize)
                if best == nil || path.count > best!.1 {
                    best = (direction, path.count)
                }
            }
            if let best {
                return Placed(id: id, row: cell.row, column: cell.column, direction: best.0)
            }
        }
        return nil
    }

    private static func collectCandidates(occupied: [GridPosition: Placed], allowed: Set<GridPosition>, gridSize: Int, rng: inout SplitMix64) -> [Candidate] {
        var result: [Candidate] = []
        for arrow in occupied.values {
            let path = PathCalculator.pathToEdge(from: arrow.position, direction: arrow.direction, gridSize: gridSize)
            for cell in path where allowed.contains(cell) && occupied[cell] == nil {
                for direction in shuffledDirections(&rng) {
                    let escape = PathCalculator.pathToEdge(from: cell, direction: direction, gridSize: gridSize)
                    if escape.contains(where: { occupied[$0] != nil }) { continue }
                    let blocked = occupied.values.filter {
                        PathCalculator.pathToEdge(from: $0.position, direction: $0.direction, gridSize: gridSize).contains(cell)
                    }
                    result.append(
                        Candidate(
                            row: cell.row,
                            column: cell.column,
                            direction: direction,
                            blockedIDs: blocked.map(\.id),
                            pathLength: escape.count
                        )
                    )
                }
            }
        }
        return result
    }

    private static func decoyCandidate(occupied: [GridPosition: Placed], allowed: Set<GridPosition>, gridSize: Int, rng: inout SplitMix64) -> Candidate? {
        let empties = allowed.filter { occupied[$0] == nil }
        guard !empties.isEmpty else { return nil }
        for _ in 0..<40 {
            let cell = Array(empties)[Int(rng.next() % UInt64(empties.count))]
            for direction in shuffledDirections(&rng) {
                let escape = PathCalculator.pathToEdge(from: cell, direction: direction, gridSize: gridSize)
                if escape.contains(where: { occupied[$0] != nil }) { continue }
                return Candidate(row: cell.row, column: cell.column, direction: direction, blockedIDs: [], pathLength: escape.count)
            }
        }
        return nil
    }

    private static func pickCandidate(_ candidates: [Candidate], placed: [Placed], archetype: LevelArchetype, rng: inout SplitMix64) -> Candidate? {
        guard !candidates.isEmpty else { return nil }
        let recentID = placed.last?.id
        let dirCounts = Dictionary(grouping: placed, by: \.direction).mapValues(\.count)
        func score(_ candidate: Candidate) -> Int {
            var value = 0
            value += candidate.blockedIDs.count * 6
            value += min(candidate.pathLength, 4)
            if let recentID, candidate.blockedIDs.contains(recentID) {
                value += chainBias(archetype)
            }
            value += fanInBias(archetype) * max(0, candidate.blockedIDs.count - 1)
            let used = dirCounts[candidate.direction] ?? 0
            value += (3 - min(used, 3)) * directionBias(archetype)
            if archetype == .singleMoveStart {
                value += candidate.blockedIDs.isEmpty ? -12 : 4
            }
            if archetype == .multipleMoveStart && candidate.blockedIDs.isEmpty {
                value += 6
            }
            return value
        }
        let ranked = candidates.shuffled(using: &rng).sorted { score($0) > score($1) }
        let take = max(1, min(6, ranked.count))
        return ranked[Int(rng.next() % UInt64(take))]
    }

    private static func decoyProbability(_ archetype: LevelArchetype) -> Double {
        switch archetype {
        case .multipleMoveStart, .shortDependencyHighBranching, .highDensityLowDepth: 0.28
        case .singleMoveStart, .deepLock, .longDependency, .bottleneck: 0.04
        case .simpleChain, .reverseChain: 0.06
        default: 0.12
        }
    }

    private static func chainBias(_ archetype: LevelArchetype) -> Int {
        switch archetype {
        case .simpleChain, .reverseChain, .longDependency, .deepLock, .chainReaction, .lowDensityHighDepth: 14
        case .zigZag, .spiralLike: 10
        default: 4
        }
    }

    private static func fanInBias(_ archetype: LevelArchetype) -> Int {
        switch archetype {
        case .bottleneck, .doubleBottleneck, .convergingDependencies, .chainReaction: 10
        case .divergingDependencies, .branchingTree: 6
        default: 3
        }
    }

    private static func directionBias(_ archetype: LevelArchetype) -> Int {
        switch archetype {
        case .mixedDirection, .asymmetricMaze, .expertChallenge, .crossDependency: 5
        default: 3
        }
    }

    private static func shuffledDirections(_ rng: inout SplitMix64) -> [Direction] {
        Direction.allCases.shuffled(using: &rng)
    }

    private static func formation(for archetype: LevelArchetype, attempt: Int, rng: inout SplitMix64) -> BoardFormation {
        let options: [BoardFormation]
        switch archetype {
        case .simpleChain, .reverseChain, .longDependency:
            options = [.staircase, .open, .offset, .asymmetric]
        case .zigZag:
            options = [.zigzag, .staircase, .offset]
        case .spiralLike:
            options = [.denseCenter, .cross, .open]
        case .cornerTrap:
            options = [.corner, .lShape]
        case .denseCenter:
            options = [.denseCenter]
        case .denseEdge:
            options = [.denseEdge, .hollow, .uShape]
        case .splitBoard, .doubleCluster, .bridge, .tripleCluster, .multiCluster:
            options = [.split, .asymmetric]
        case .asymmetricMaze:
            options = [.asymmetric, .offset, .lShape]
        case .lowDensityHighDepth:
            options = [.open, .staircase, .offset]
        case .highDensityLowDepth:
            options = [.open, .denseCenter, .denseEdge]
        case .mixedDirection, .crossDependency, .mixedComplexity:
            options = [.open, .lShape, .tShape, .cross, .offset]
        default:
            options = [.open, .lShape, .tShape, .cross, .staircase, .corner, .uShape, .asymmetric, .offset]
        }
        _ = attempt
        return options[Int(rng.next() % UInt64(options.count))]
    }

    private static func formationCells(_ formation: BoardFormation, gridSize: Int) -> Set<GridPosition> {
        var result: Set<GridPosition> = []
        let last = gridSize - 1
        let mid = gridSize / 2
        for row in 0..<gridSize {
            for column in 0..<gridSize {
                let include: Bool
                switch formation {
                case .open:
                    include = true
                case .lShape:
                    include = row >= last - max(1, gridSize / 3) || column <= max(1, gridSize / 3)
                case .tShape:
                    include = row <= max(1, gridSize / 4) || abs(column - mid) <= max(1, gridSize / 5)
                case .cross:
                    include = abs(row - mid) <= max(1, gridSize / 6) || abs(column - mid) <= max(1, gridSize / 6)
                case .staircase:
                    include = abs(row - column) <= max(1, gridSize / 5)
                case .corner:
                    include = row <= (gridSize * 2) / 3 && column <= (gridSize * 2) / 3
                case .hollow:
                    include = row <= 1 || column <= 1 || row >= last - 1 || column >= last - 1
                case .uShape:
                    include = column == 0 || column == last || row >= last - max(1, gridSize / 4)
                case .zigzag:
                    include = ((row + column * 2) % 3) != 0 || abs(row - column) <= 1
                case .asymmetric:
                    include = column < (gridSize * 2) / 3 || (row > mid && column >= mid)
                case .split:
                    include = column <= mid - (gridSize > 5 ? 1 : 0) || column >= mid + (gridSize > 5 ? 1 : 0)
                case .denseCenter:
                    include = max(abs(row - mid), abs(column - mid)) <= max(2, gridSize / 3)
                case .denseEdge:
                    include = row <= 1 || column <= 1 || row >= last - 1 || column >= last - 1
                case .offset:
                    include = (row % 2 == 0 && column >= gridSize / 4) || (row % 2 == 1 && column <= (gridSize * 3) / 4)
                }
                if include {
                    result.insert(GridPosition(row: row, column: column))
                }
            }
        }
        return result
    }

    private static func region(gridSize: Int, predicate: (Int, Int) -> Bool) -> Set<GridPosition> {
        var cells: Set<GridPosition> = []
        for row in 0..<gridSize {
            for column in 0..<gridSize where predicate(row, column) {
                cells.insert(GridPosition(row: row, column: column))
            }
        }
        return cells
    }

    private static func handcrafted(id: Int) -> Level? {
        switch id {
        case 1:
            return make(id, 3, .tutorial, .simpleChain, [
                a(1, 1, 0, .right)
            ])
        case 2:
            return make(id, 3, .easy, .reverseChain, [
                a(1, 1, 2, .up),
                a(2, 1, 0, .right)
            ])
        case 3:
            return make(id, 3, .easy, .simpleChain, [
                a(1, 0, 2, .left),
                a(2, 2, 2, .up),
                a(3, 2, 0, .right)
            ])
        case 4:
            return make(id, 4, .easy, .mixedDirection, [
                a(1, 0, 3, .down),
                a(2, 3, 3, .left),
                a(3, 3, 0, .up),
                a(4, 1, 0, .right)
            ])
        case 5:
            return make(id, 4, .easy, .branchingTree, [
                a(1, 0, 2, .left),
                a(2, 0, 0, .down),
                a(3, 3, 0, .right),
                a(4, 3, 3, .up),
                a(5, 1, 3, .left)
            ])
        case 6:
            return make(id, 4, .easy, .zigZag, [
                a(1, 0, 1, .right),
                a(2, 0, 3, .down),
                a(3, 2, 3, .left),
                a(4, 2, 1, .down),
                a(5, 3, 1, .left),
                a(6, 3, 0, .up)
            ])
        case 7:
            return make(id, 4, .easy, .singleMoveStart, [
                a(1, 1, 0, .down),
                a(2, 3, 0, .right),
                a(3, 3, 2, .up),
                a(4, 1, 2, .right),
                a(5, 1, 3, .down),
                a(6, 3, 3, .right)
            ])
        case 8:
            return make(id, 5, .easy, .cornerTrap, [
                a(1, 0, 4, .left),
                a(2, 0, 2, .down),
                a(3, 2, 2, .left),
                a(4, 2, 0, .down),
                a(5, 4, 0, .right),
                a(6, 4, 3, .up)
            ])
        case 9:
            return make(id, 5, .easy, .multipleMoveStart, [
                a(1, 0, 0, .right),
                a(2, 0, 4, .down),
                a(3, 2, 4, .left),
                a(4, 2, 2, .down),
                a(5, 4, 2, .left),
                a(6, 4, 0, .left),
                a(7, 1, 0, .right)
            ])
        case 10:
            return make(id, 5, .easy, .branchingTree, [
                a(1, 2, 2, .left),
                a(2, 2, 4, .left),
                a(3, 4, 2, .up),
                a(4, 0, 2, .down),
                a(5, 4, 4, .left),
                a(6, 0, 4, .left),
                a(7, 4, 0, .up)
            ])
        default:
            return nil
        }
    }

    private static func make(_ id: Int, _ grid: Int, _ difficulty: Difficulty, _ archetype: LevelArchetype, _ arrows: [ArrowData]) -> Level {
        Level(
            id: id,
            gridSize: grid,
            parMoves: arrows.count,
            difficulty: difficulty,
            arrows: arrows,
            seed: 9000 + id,
            archetype: archetype.rawValue
        )
    }

    private static func a(_ id: Int, _ row: Int, _ column: Int, _ direction: Direction) -> ArrowData {
        ArrowData(id: id, row: row, column: column, direction: direction)
    }
}

private extension Array {
    func shuffled(using rng: inout SplitMix64) -> [Element] {
        var copy = self
        var index = copy.count
        while index > 1 {
            index -= 1
            let pick = Int(rng.next() % UInt64(index + 1))
            copy.swapAt(index, pick)
        }
        return copy
    }
}
