import Foundation

struct SolverReport: Sendable, Equatable {
    var isSolvable: Bool
    var solution: [Int]
    var optimalMoves: Int
    var solutionDepth: Int
    var initialMoveCount: Int
    var nodesExpanded: Int
    var branchingAlongSolution: [Int]
}

enum LevelSolver {
    static func isSolvable(_ level: Level) -> Bool {
        solve(level: level) != nil
    }

    static func solve(level: Level) -> [Int]? {
        solve(level: level, remaining: level.arrows.map { Arrow(from: $0) })
    }

    static func solve(level: Level, remaining: [Arrow]) -> [Int]? {
        report(level: level, remaining: remaining)?.solution
    }

    static func report(level: Level, maxNodes: Int = 80_000) -> SolverReport? {
        report(level: level, remaining: level.arrows.map { Arrow(from: $0) }, maxNodes: maxNodes)
    }

    static func sequenceClears(_ order: [Int], level: Level) -> Bool {
        var remaining = Dictionary(uniqueKeysWithValues: level.arrows.map { ($0.id, $0) })
        if order.count != remaining.count { return false }
        var seen: Set<Int> = []
        for id in order {
            guard seen.insert(id).inserted, let arrow = remaining[id] else { return false }
            var occupied: [GridPosition: Int] = [:]
            occupied.reserveCapacity(remaining.count)
            for item in remaining.values {
                occupied[item.position] = item.id
            }
            if !LevelGraph.canEscape(arrow, occupancy: occupied, gridSize: level.gridSize) {
                return false
            }
            remaining.removeValue(forKey: id)
        }
        return remaining.isEmpty
    }

    static func report(level: Level, remaining: [Arrow], maxNodes: Int = 80_000) -> SolverReport? {
        let scaledCap = max(maxNodes, min(280_000, 24_000 + remaining.count * 5_000))
        if remaining.count >= 18 {
            if let dfs = search(level: level, remaining: remaining, maxNodes: scaledCap, depthFirst: true) {
                return dfs
            }
            return search(level: level, remaining: remaining, maxNodes: scaledCap, depthFirst: false)
        }
        if let bfs = search(level: level, remaining: remaining, maxNodes: scaledCap, depthFirst: false) {
            return bfs
        }
        return search(level: level, remaining: remaining, maxNodes: scaledCap, depthFirst: true)
    }

    private static func search(level: Level, remaining: [Arrow], maxNodes: Int, depthFirst: Bool) -> SolverReport? {
        let actives = remaining.filter(\.isActive)
        if actives.isEmpty {
            return SolverReport(
                isSolvable: true,
                solution: [],
                optimalMoves: 0,
                solutionDepth: 0,
                initialMoveCount: 0,
                nodesExpanded: 0,
                branchingAlongSolution: []
            )
        }

        var idToArrow: [Int: Arrow] = [:]
        for arrow in actives {
            idToArrow[arrow.id] = arrow
        }
        let ids = actives.map(\.id).sorted()
        var indexOf: [Int: Int] = [:]
        for (index, id) in ids.enumerated() {
            indexOf[id] = index
        }

        func mask(for remainingIDs: [Int]) -> UInt64 {
            var value: UInt64 = 0
            for id in remainingIDs {
                if let index = indexOf[id], index < 64 {
                    value |= 1 << index
                }
            }
            return value
        }

        struct Node {
            var state: UInt64
            var movedID: Int
            var parent: Int
        }

        let startMask = mask(for: ids)
        var visited: Set<UInt64> = [startMask]
        var nodes: [Node] = [Node(state: startMask, movedID: -1, parent: -1)]
        var stack: [Int] = [0]
        var goalIndex: Int?

        while let currentIndex = stack.popLast() {
            let current = nodes[currentIndex]
            let state = current.state
            if state == 0 {
                goalIndex = currentIndex
                break
            }

            let remainingIDs = ids.enumerated().compactMap { index, id in
                ((state >> index) & 1) == 1 ? id : nil
            }

            var occupied: [GridPosition: Int] = [:]
            occupied.reserveCapacity(remainingIDs.count)
            for id in remainingIDs {
                if let arrow = idToArrow[id] {
                    occupied[arrow.position] = id
                }
            }

            if nodes.count > maxNodes {
                return nil
            }

            var spawned: [Int] = []
            for id in remainingIDs {
                guard let arrow = idToArrow[id] else { continue }
                var blocked = false
                var cursor = arrow.position.stepped(in: arrow.direction)
                while cursor.isInside(gridSize: level.gridSize) {
                    if occupied[cursor] != nil {
                        blocked = true
                        break
                    }
                    cursor = cursor.stepped(in: arrow.direction)
                }
                if blocked { continue }

                guard let index = indexOf[id] else { continue }
                let next = state & ~(UInt64(1) << index)
                if visited.contains(next) { continue }
                visited.insert(next)
                nodes.append(Node(state: next, movedID: id, parent: currentIndex))
                spawned.append(nodes.count - 1)
            }
            if depthFirst {
                stack.append(contentsOf: spawned.reversed())
            } else {
                stack = spawned + stack
            }
        }

        guard let goal = goalIndex else {
            return nil
        }

        var path: [Int] = []
        var cursor = goal
        while nodes[cursor].parent >= 0 {
            path.append(nodes[cursor].movedID)
            cursor = nodes[cursor].parent
        }
        path.reverse()

        let startLevel = Level(
            id: level.id,
            gridSize: level.gridSize,
            parMoves: level.parMoves,
            difficulty: level.difficulty,
            arrows: actives.map {
                ArrowData(id: $0.id, row: $0.position.row, column: $0.position.column, direction: $0.direction)
            },
            seed: level.seed,
            archetype: level.archetype,
            patternType: level.patternType,
            patternFamily: level.patternFamily
        )
        let edges = LevelGraph.blockingAdjacency(startLevel)
        let depth = LevelGraph.longestChain(edges)
        let initial = LevelGraph.initialMoveIDs(startLevel).count
        let branching = branchingProfile(level: startLevel, solution: path)

        return SolverReport(
            isSolvable: true,
            solution: path,
            optimalMoves: path.count,
            solutionDepth: depth,
            initialMoveCount: initial,
            nodesExpanded: visited.count,
            branchingAlongSolution: branching
        )
    }

    private static func branchingProfile(level: Level, solution: [Int]) -> [Int] {
        var remaining = Dictionary(uniqueKeysWithValues: level.arrows.map { ($0.id, $0) })
        var profile: [Int] = []
        for move in solution {
            let snapshot = Level(
                id: level.id,
                gridSize: level.gridSize,
                parMoves: remaining.count,
                difficulty: level.difficulty,
                arrows: Array(remaining.values),
                seed: level.seed
            )
            profile.append(LevelGraph.initialMoveIDs(snapshot).count)
            remaining.removeValue(forKey: move)
        }
        return profile
    }
}
