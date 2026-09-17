import Foundation

enum BoardFormation: CaseIterable, Sendable {
    case open, lShape, tShape, cross, staircase, corner, hollow, uShape, zigzag, asymmetric, split, denseCenter, denseEdge, offset
}

enum PatternLayout {
    struct Placed: Sendable {
        var id: Int
        var row: Int
        var column: Int
        var direction: Direction

        var data: ArrowData {
            ArrowData(id: id, row: row, column: column, direction: direction)
        }

        var position: GridPosition { GridPosition(row: row, column: column) }
    }

    static func realize(
        graph: DependencyGraph,
        gridSize: Int,
        formation: BoardFormation,
        transform: Int,
        rng: inout SplitMix64
    ) -> [Placed]? {
        var allowed = formationCells(formation, gridSize: gridSize)
        if allowed.count < graph.nodeCount + 1 {
            allowed = formationCells(.open, gridSize: gridSize)
        }

        var placed: [Int: Placed] = [:]
        var occupied: [GridPosition: Int] = [:]

        let hubs = graph.hubIDs.sorted { graph.outDegree($0) > graph.outDegree($1) }
        for hub in hubs {
            guard placed[hub] == nil else { continue }
            let preferEdge = graph.layoutHint == .edgeStar
            guard let cell = pickHubCell(
                gridSize: gridSize,
                allowed: allowed,
                occupied: occupied,
                preferEdge: preferEdge,
                rng: &rng
            ) else { return nil }
            let direction = hubEscapeDirection(
                from: cell,
                gridSize: gridSize,
                occupied: occupied,
                reservedSpokes: graph.outDegree(hub)
            )
            occupy(&placed, &occupied, Placed(id: hub, row: cell.row, column: cell.column, direction: direction))
            placeSpokes(
                of: hub,
                graph: graph,
                gridSize: gridSize,
                allowed: allowed,
                placed: &placed,
                occupied: &occupied,
                rng: &rng
            )
        }

        let order = reverseTopological(graph)
        for node in order where placed[node] == nil {
            if graph.decoys.contains(node) {
                if let decoy = placeDecoy(id: node, gridSize: gridSize, allowed: allowed, occupied: occupied, rng: &rng) {
                    occupy(&placed, &occupied, decoy)
                    continue
                }
            }
            let dependents = graph.dependents(of: node).filter { placed[$0] != nil }
            if let pick = placeBlocker(
                id: node,
                of: dependents.compactMap { placed[$0] },
                gridSize: gridSize,
                allowed: allowed,
                occupied: occupied,
                rng: &rng
            ) {
                occupy(&placed, &occupied, pick)
                continue
            }
            if let seed = placeSeed(id: node, gridSize: gridSize, allowed: allowed, occupied: occupied, rng: &rng) {
                occupy(&placed, &occupied, seed)
                continue
            }
            return nil
        }

        for node in graph.nodeIDs where placed[node] == nil {
            if let seed = placeSeed(id: node, gridSize: gridSize, allowed: allowed, occupied: occupied, rng: &rng)
                ?? placeDecoy(id: node, gridSize: gridSize, allowed: allowed, occupied: occupied, rng: &rng) {
                occupy(&placed, &occupied, seed)
            } else {
                return nil
            }
        }

        guard placed.count == graph.nodeCount else { return nil }
        let arrows = graph.nodeIDs.compactMap { placed[$0] }
        return arrows.map { applyTransform($0, mode: transform, grid: gridSize) }
    }

    static func formation(for pattern: PuzzlePattern, attempt: Int, rng: inout SplitMix64) -> BoardFormation {
        let options: [BoardFormation]
        switch pattern.family {
        case .chain:
            options = pattern == .zigzagChain
                ? [.zigzag, .staircase, .offset]
                : [.staircase, .open, .offset, .asymmetric, .lShape]
        case .branching:
            options = [.open, .tShape, .cross, .asymmetric]
        case .bottleneck:
            options = pattern == .edgeBottleneck
                ? [.denseEdge, .uShape, .corner]
                : [.denseCenter, .cross, .open]
        case .cross:
            options = [.cross, .open, .tShape]
        case .cluster:
            options = [.split, .asymmetric, .offset]
        case .advanced, .hybrid:
            options = [.open, .asymmetric, .lShape, .split, .offset, .hollow]
        }
        _ = attempt
        return options[Int(rng.next() % UInt64(options.count))]
    }

    static func formationCells(_ formation: BoardFormation, gridSize: Int) -> Set<GridPosition> {
        var result: Set<GridPosition> = []
        let last = gridSize - 1
        let mid = gridSize / 2
        for row in 0..<gridSize {
            for column in 0..<gridSize {
                let include: Bool
                switch formation {
                case .open: include = true
                case .lShape: include = row >= last - max(1, gridSize / 3) || column <= max(1, gridSize / 3)
                case .tShape: include = row <= max(1, gridSize / 4) || abs(column - mid) <= max(1, gridSize / 5)
                case .cross: include = abs(row - mid) <= max(1, gridSize / 6) || abs(column - mid) <= max(1, gridSize / 6)
                case .staircase: include = abs(row - column) <= max(1, gridSize / 5)
                case .corner: include = row <= (gridSize * 2) / 3 && column <= (gridSize * 2) / 3
                case .hollow: include = row <= 1 || column <= 1 || row >= last - 1 || column >= last - 1
                case .uShape: include = column == 0 || column == last || row >= last - max(1, gridSize / 4)
                case .zigzag: include = ((row + column * 2) % 3) != 0 || abs(row - column) <= 1
                case .asymmetric: include = column < (gridSize * 2) / 3 || (row > mid && column >= mid)
                case .split: include = column <= mid - (gridSize > 5 ? 1 : 0) || column >= mid + (gridSize > 5 ? 1 : 0)
                case .denseCenter: include = max(abs(row - mid), abs(column - mid)) <= max(2, gridSize / 3)
                case .denseEdge: include = row <= 1 || column <= 1 || row >= last - 1 || column >= last - 1
                case .offset: include = (row % 2 == 0 && column >= gridSize / 4) || (row % 2 == 1 && column <= (gridSize * 3) / 4)
                }
                if include {
                    result.insert(GridPosition(row: row, column: column))
                }
            }
        }
        return result
    }

    private static func occupy(_ placed: inout [Int: Placed], _ occupied: inout [GridPosition: Int], _ arrow: Placed) {
        placed[arrow.id] = arrow
        occupied[arrow.position] = arrow.id
    }

    private static func reverseTopological(_ graph: DependencyGraph) -> [Int] {
        var remaining = Set(graph.nodeIDs)
        var result: [Int] = []
        var incoming = Dictionary(uniqueKeysWithValues: graph.nodeIDs.map { ($0, graph.incoming($0)) })
        while !remaining.isEmpty {
            let leaves = remaining.filter { incoming[$0, default: 0] == 0 }.sorted()
            let batch = leaves.isEmpty ? [remaining.min()!] : leaves
            for node in batch {
                remaining.remove(node)
                result.append(node)
                for dep in graph.dependents(of: node) {
                    incoming[dep, default: 1] -= 1
                }
            }
        }
        return result.reversed()
    }

    private static func pickHubCell(
        gridSize: Int,
        allowed: Set<GridPosition>,
        occupied: [GridPosition: Int],
        preferEdge: Bool,
        rng: inout SplitMix64
    ) -> GridPosition? {
        let last = gridSize - 1
        let mid = gridSize / 2
        let free = allowed.filter { occupied[$0] == nil }
        let ranked = free.sorted { a, b in
            let da = max(min(a.row, last - a.row), min(a.column, last - a.column))
            let db = max(min(b.row, last - b.row), min(b.column, last - b.column))
            if preferEdge { return da < db }
            let ra = abs(a.row - mid) + abs(a.column - mid)
            let rb = abs(b.row - mid) + abs(b.column - mid)
            return ra < rb
        }
        guard !ranked.isEmpty else { return nil }
        let take = min(6, ranked.count)
        return ranked[Int(rng.next() % UInt64(take))]
    }

    private static func hubEscapeDirection(
        from cell: GridPosition,
        gridSize: Int,
        occupied: [GridPosition: Int],
        reservedSpokes: Int
    ) -> Direction {
        let dirs = Direction.allCases.sorted {
            PathCalculator.pathToEdge(from: cell, direction: $0, gridSize: gridSize).count
                > PathCalculator.pathToEdge(from: cell, direction: $1, gridSize: gridSize).count
        }
        for direction in dirs {
            let path = PathCalculator.pathToEdge(from: cell, direction: direction, gridSize: gridSize)
            if path.allSatisfy({ occupied[$0] == nil }) {
                return direction
            }
        }
        _ = reservedSpokes
        return dirs.first ?? .up
    }

    private static func placeSpokes(
        of hub: Int,
        graph: DependencyGraph,
        gridSize: Int,
        allowed: Set<GridPosition>,
        placed: inout [Int: Placed],
        occupied: inout [GridPosition: Int],
        rng: inout SplitMix64
    ) {
        guard let hubArrow = placed[hub] else { return }
        let spokeIDs = graph.dependents(of: hub).filter { placed[$0] == nil }
        let blockedDir = hubArrow.direction
        var axes = Direction.allCases.filter { $0 != blockedDir }
        axes = axes.shuffled(using: &rng)
        for (index, spoke) in spokeIDs.prefix(3).enumerated() {
            let axis = axes[index % axes.count]
            let towardHub = opposite(axis)
            if let cell = firstFree(
                from: hubArrow.position.stepped(in: axis),
                direction: axis,
                gridSize: gridSize,
                allowed: allowed,
                occupied: occupied,
                skip: Int(rng.next() % 2)
            ) {
                occupy(&placed, &occupied, Placed(id: spoke, row: cell.row, column: cell.column, direction: towardHub))
            }
        }
    }

    private static func firstFree(
        from start: GridPosition,
        direction: Direction,
        gridSize: Int,
        allowed: Set<GridPosition>,
        occupied: [GridPosition: Int],
        skip: Int
    ) -> GridPosition? {
        var cursor = start
        var skipped = 0
        while cursor.isInside(gridSize: gridSize) {
            if allowed.contains(cursor), occupied[cursor] == nil {
                if skipped >= skip { return cursor }
                skipped += 1
            }
            cursor = cursor.stepped(in: direction)
        }
        return nil
    }

    private static func placeBlocker(
        id: Int,
        of dependents: [Placed],
        gridSize: Int,
        allowed: Set<GridPosition>,
        occupied: [GridPosition: Int],
        rng: inout SplitMix64
    ) -> Placed? {
        guard !dependents.isEmpty else { return nil }
        var candidates: [Placed] = []
        for target in dependents.shuffled(using: &rng) {
            let path = PathCalculator.pathToEdge(from: target.position, direction: target.direction, gridSize: gridSize)
            for cell in path where allowed.contains(cell) && occupied[cell] == nil {
                for direction in Direction.allCases.shuffled(using: &rng) {
                    let escape = PathCalculator.pathToEdge(from: cell, direction: direction, gridSize: gridSize)
                    if escape.contains(where: { occupied[$0] != nil }) { continue }
                    if direction == target.direction && cell.row == target.row && cell.column == target.column {
                        continue
                    }
                    candidates.append(Placed(id: id, row: cell.row, column: cell.column, direction: direction))
                }
            }
        }
        guard !candidates.isEmpty else { return nil }
        let scored = candidates.sorted { lhs, rhs in
            let ls = dependents.filter { PathCalculator.pathToEdge(from: $0.position, direction: $0.direction, gridSize: gridSize).contains(lhs.position) }.count
            let rs = dependents.filter { PathCalculator.pathToEdge(from: $0.position, direction: $0.direction, gridSize: gridSize).contains(rhs.position) }.count
            if ls != rs { return ls > rs }
            return PathCalculator.pathToEdge(from: lhs.position, direction: lhs.direction, gridSize: gridSize).count
                > PathCalculator.pathToEdge(from: rhs.position, direction: rhs.direction, gridSize: gridSize).count
        }
        let take = min(5, scored.count)
        return scored[Int(rng.next() % UInt64(take))]
    }

    private static func placeSeed(
        id: Int,
        gridSize: Int,
        allowed: Set<GridPosition>,
        occupied: [GridPosition: Int],
        rng: inout SplitMix64
    ) -> Placed? {
        let last = gridSize - 1
        let pool = Array(allowed.filter { occupied[$0] == nil && $0.row > 0 && $0.column > 0 && $0.row < last && $0.column < last })
            + Array(allowed.filter { occupied[$0] == nil })
        guard !pool.isEmpty else { return nil }
        for _ in 0..<32 {
            let cell = pool[Int(rng.next() % UInt64(pool.count))]
            let dirs = Direction.allCases.shuffled(using: &rng)
            if let direction = dirs.first(where: { dir in
                PathCalculator.pathToEdge(from: cell, direction: dir, gridSize: gridSize)
                    .allSatisfy { occupied[$0] == nil }
            }) {
                return Placed(id: id, row: cell.row, column: cell.column, direction: direction)
            }
        }
        return nil
    }

    private static func placeDecoy(
        id: Int,
        gridSize: Int,
        allowed: Set<GridPosition>,
        occupied: [GridPosition: Int],
        rng: inout SplitMix64
    ) -> Placed? {
        let empties = Array(allowed.filter { occupied[$0] == nil })
        guard !empties.isEmpty else { return nil }
        for _ in 0..<40 {
            let cell = empties[Int(rng.next() % UInt64(empties.count))]
            for direction in Direction.allCases.shuffled(using: &rng) {
                let escape = PathCalculator.pathToEdge(from: cell, direction: direction, gridSize: gridSize)
                if escape.contains(where: { occupied[$0] != nil }) { continue }
                return Placed(id: id, row: cell.row, column: cell.column, direction: direction)
            }
        }
        return nil
    }

    private static func opposite(_ direction: Direction) -> Direction {
        switch direction {
        case .up: .down
        case .down: .up
        case .left: .right
        case .right: .left
        }
    }

    private static func applyTransform(_ arrow: Placed, mode: Int, grid: Int) -> Placed {
        let last = grid - 1
        let row: Int
        let column: Int
        let direction: Direction
        switch mode % 8 {
        case 1:
            row = arrow.column
            column = last - arrow.row
            direction = rotate(arrow.direction)
        case 2:
            row = last - arrow.row
            column = last - arrow.column
            direction = rotate(rotate(arrow.direction))
        case 3:
            row = last - arrow.column
            column = arrow.row
            direction = rotate(rotate(rotate(arrow.direction)))
        case 4:
            row = arrow.row
            column = last - arrow.column
            direction = mirrorH(arrow.direction)
        case 5:
            row = last - arrow.row
            column = arrow.column
            direction = mirrorV(arrow.direction)
        case 6:
            row = arrow.column
            column = arrow.row
            direction = transpose(arrow.direction)
        default:
            return arrow
        }
        return Placed(id: arrow.id, row: row, column: column, direction: direction)
    }

    private static func rotate(_ direction: Direction) -> Direction {
        switch direction {
        case .up: .right
        case .right: .down
        case .down: .left
        case .left: .up
        }
    }

    private static func mirrorH(_ direction: Direction) -> Direction {
        switch direction {
        case .left: .right
        case .right: .left
        default: direction
        }
    }

    private static func mirrorV(_ direction: Direction) -> Direction {
        switch direction {
        case .up: .down
        case .down: .up
        default: direction
        }
    }

    private static func transpose(_ direction: Direction) -> Direction {
        switch direction {
        case .up: .left
        case .left: .up
        case .down: .right
        case .right: .down
        }
    }
}

extension Array {
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
