import Foundation

enum LevelGraph {
    static func occupancy(_ level: Level) -> [GridPosition: Int] {
        occupancy(arrows: level.arrows)
    }

    static func occupancy(arrows: [ArrowData]) -> [GridPosition: Int] {
        var map: [GridPosition: Int] = [:]
        for arrow in arrows {
            map[arrow.position] = arrow.id
        }
        return map
    }

    static func pathCells(from arrow: ArrowData, gridSize: Int) -> [GridPosition] {
        PathCalculator.pathToEdge(from: arrow.position, direction: arrow.direction, gridSize: gridSize)
    }

    static func blockers(of arrow: ArrowData, occupancy: [GridPosition: Int], gridSize: Int) -> [Int] {
        var ids: [Int] = []
        for cell in pathCells(from: arrow, gridSize: gridSize) {
            if let blocker = occupancy[cell] {
                ids.append(blocker)
            }
        }
        return ids
    }

    static func canEscape(_ arrow: ArrowData, occupancy: [GridPosition: Int], gridSize: Int) -> Bool {
        blockers(of: arrow, occupancy: occupancy, gridSize: gridSize).isEmpty
    }

    /// Edge: blocker ID → arrows it directly obstructs.
    static func blockingAdjacency(_ level: Level) -> [Int: [Int]] {
        let occupied = occupancy(level)
        var edges: [Int: [Int]] = [:]
        for arrow in level.arrows {
            edges[arrow.id, default: []] = []
        }
        for arrow in level.arrows {
            for blocker in blockers(of: arrow, occupancy: occupied, gridSize: level.gridSize) {
                edges[blocker, default: []].append(arrow.id)
            }
        }
        return edges
    }

    static func longestChain(_ edges: [Int: [Int]]) -> Int {
        var memo: [Int: Int] = [:]
        var onStack: Set<Int> = []
        func depth(_ node: Int) -> Int {
            if let cached = memo[node] { return cached }
            if onStack.contains(node) { return 1 }
            onStack.insert(node)
            let children = edges[node] ?? []
            let value = 1 + (children.map(depth).max() ?? 0)
            onStack.remove(node)
            memo[node] = value
            return value
        }
        return edges.keys.map(depth).max() ?? 1
    }

    static func bottleneckCount(_ edges: [Int: [Int]], threshold: Int = 3) -> Int {
        edges.values.filter { Set($0).count >= threshold }.count
    }

    static func branchCount(_ edges: [Int: [Int]]) -> Int {
        edges.values.filter { Set($0).count >= 2 }.count
    }

    static func dependencyCount(_ edges: [Int: [Int]]) -> Int {
        edges.values.reduce(0) { $0 + Set($1).count }
    }

    static func initialMoveIDs(_ level: Level) -> [Int] {
        let occupied = occupancy(level)
        return level.arrows
            .filter { canEscape($0, occupancy: occupied, gridSize: level.gridSize) }
            .map(\.id)
            .sorted()
    }

    static func clusterCount(_ level: Level) -> Int {
        let cellToID = occupancy(level)
        var remaining = Set(level.arrows.map(\.id))
        var clusters = 0
        let byID = Dictionary(uniqueKeysWithValues: level.arrows.map { ($0.id, $0) })
        while let start = remaining.first {
            clusters += 1
            var stack = [start]
            remaining.remove(start)
            while let current = stack.popLast() {
                guard let arrow = byID[current] else { continue }
                let neighbors = [
                    GridPosition(row: arrow.position.row - 1, column: arrow.position.column),
                    GridPosition(row: arrow.position.row + 1, column: arrow.position.column),
                    GridPosition(row: arrow.position.row, column: arrow.position.column - 1),
                    GridPosition(row: arrow.position.row, column: arrow.position.column + 1)
                ]
                for cell in neighbors {
                    if let other = cellToID[cell], remaining.contains(other) {
                        remaining.remove(other)
                        stack.append(other)
                    }
                }
            }
        }
        return max(clusters, 1)
    }

    static func directionHistogram(_ level: Level) -> [Direction: Int] {
        var counts: [Direction: Int] = [:]
        for direction in Direction.allCases { counts[direction] = 0 }
        for arrow in level.arrows {
            counts[arrow.direction, default: 0] += 1
        }
        return counts
    }

    static func density(_ level: Level) -> Double {
        let cells = max(level.gridSize * level.gridSize, 1)
        return Double(level.arrowCount) / Double(cells)
    }

    static func hasOverlaps(_ level: Level) -> Bool {
        occupancy(level).count != level.arrows.count
    }

    static func hasOutOfBounds(_ level: Level) -> Bool {
        level.arrows.contains { !$0.position.isInside(gridSize: level.gridSize) }
    }
}
