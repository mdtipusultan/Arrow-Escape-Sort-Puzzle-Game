import Foundation

enum LevelSolver {
    static func isSolvable(_ level: Level) -> Bool {
        solve(level: level) != nil
    }

    static func solve(level: Level) -> [Int]? {
        let arrows = level.arrows.map { Arrow(from: $0) }
        return solve(level: level, remaining: arrows)
    }

    static func solve(level: Level, remaining: [Arrow]) -> [Int]? {
        let actives = remaining.filter(\.isActive)
        if actives.isEmpty { return [] }

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

        let startMask = mask(for: ids)
        var visited: Set<UInt64> = [startMask]
        var queue: [(UInt64, [Int])] = [(startMask, [])]
        var head = 0

        while head < queue.count {
            let (state, path) = queue[head]
            head += 1
            if state == 0 {
                return path
            }

            let remainingIDs = ids.enumerated().compactMap { index, id in
                ((state >> index) & 1) == 1 ? id : nil
            }

            var occupied: [GridPosition: Int] = [:]
            for id in remainingIDs {
                if let arrow = idToArrow[id] {
                    occupied[arrow.position] = id
                }
            }

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
                queue.append((next, path + [id]))
            }
        }

        return nil
    }
}
