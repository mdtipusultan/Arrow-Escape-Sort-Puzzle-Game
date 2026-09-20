import Foundation

enum LevelGenerator {
    static func generate(spec: LevelSpec, previous: [Level] = []) -> Level? {
        if let crafted = handcrafted(id: spec.id) {
            return PatternEngine.finalize(crafted, spec: spec) ?? crafted
        }
        if let constructed = PuzzleConstructor.build(spec: spec, previous: previous) {
            return constructed
        }
        if let generated = PatternEngine.generate(spec: spec, previous: previous),
           DifficultyAnalyzer.meetsIntent(LevelAnalyzer.analyze(generated), spec: spec, relax: spec.id < 21) {
            return generated
        }
        if let constructed = PuzzleConstructor.build(spec: spec, previous: previous) {
            return constructed
        }
        if let generated = PatternEngine.generate(spec: spec, previous: previous) {
            return generated
        }
        return PuzzleConstructor.build(spec: spec, previous: previous)
            ?? PatternEngine.finalize(designedGuarantee(spec: spec), spec: spec)
            ?? designedGuarantee(spec: spec)
    }

    static func guaranteedLevel(spec: LevelSpec) -> Level {
        PuzzleConstructor.build(spec: spec) ?? designedGuarantee(spec: spec)
    }

    /// Structured fallback: disjoint-axis chains so paths cannot deadlock.
    private static func designedGuarantee(spec: LevelSpec) -> Level {
        let grid = max(spec.gridSize, 4)
        let count = min(max(spec.arrowCount, 1), grid * grid - 1)
        let candidates = [
            disjointAxisLevel(id: spec.id, grid: grid, count: count, difficulty: spec.difficulty, pattern: spec.pattern, seed: spec.seed, phase: 0),
            disjointAxisLevel(id: spec.id, grid: grid, count: count, difficulty: spec.difficulty, pattern: spec.pattern, seed: spec.seed, phase: 1),
            disjointAxisLevel(id: spec.id, grid: grid, count: max(3, count - 2), difficulty: spec.difficulty, pattern: spec.pattern, seed: spec.seed, phase: 2)
        ]
        for candidate in candidates {
            if LevelSolver.isSolvable(candidate) {
                return candidate
            }
        }
        return disjointAxisLevel(id: spec.id, grid: grid, count: min(6, count), difficulty: spec.difficulty, pattern: spec.pattern, seed: spec.seed, phase: 0)
    }

    private static func disjointAxisLevel(
        id: Int,
        grid: Int,
        count: Int,
        difficulty: Difficulty,
        pattern: PuzzlePattern,
        seed: Int,
        phase: Int
    ) -> Level {
        var occupied: Set<GridPosition> = []
        var arrows: [ArrowData] = []
        var nextID = 1

        func placeChain(cells: [GridPosition], direction: Direction, limit: Int) {
            var placed = 0
            for cell in cells {
                guard placed < limit, cell.isInside(gridSize: grid), !occupied.contains(cell) else { continue }
                occupied.insert(cell)
                arrows.append(ArrowData(id: nextID, row: cell.row, column: cell.column, direction: direction))
                nextID += 1
                placed += 1
            }
        }

        let hRows = [0, 2].map { ($0 + phase) % max(grid - 2, 1) }
        let vCols = [grid - 1, grid - 2]
        let leftRow = grid - 1
        let upCol = (grid > 4 ? max(0, grid - 3) : 0)
        let quota = max(2, (count + 3) / 4)

        let hCols = Array(0..<(max(2, grid - 3)))
        for row in hRows where row != leftRow {
            placeChain(cells: hCols.map { GridPosition(row: row, column: $0) }, direction: .right, limit: quota)
        }

        let vRows = Array(1..<(grid - 1)).filter { !hRows.contains($0) && $0 != leftRow }
        for column in vCols where column != upCol {
            placeChain(cells: vRows.map { GridPosition(row: $0, column: column) }, direction: .down, limit: quota)
        }

        let leftCols = Array(1..<(grid - 1)).filter { !vCols.contains($0) && $0 != upCol }
        placeChain(cells: leftCols.map { GridPosition(row: leftRow, column: $0) }, direction: .left, limit: quota)

        let upRows = Array(1..<(grid - 1)).filter { !hRows.contains($0) && $0 != leftRow }
        placeChain(cells: upRows.map { GridPosition(row: $0, column: upCol) }, direction: .up, limit: quota)

        let leftovers: [(GridPosition, Direction)] =
            hRows.flatMap { row in hCols.map { (GridPosition(row: row, column: $0), Direction.right) } } +
            vCols.flatMap { column in vRows.map { (GridPosition(row: $0, column: column), Direction.down) } }
        for (cell, direction) in leftovers where arrows.count < count {
            placeChain(cells: [cell], direction: direction, limit: 1)
        }

        return Level(
            id: id,
            gridSize: grid,
            parMoves: arrows.count,
            difficulty: difficulty,
            arrows: Array(arrows.prefix(count)),
            seed: seed,
            archetype: pattern.rawValue,
            patternType: pattern.rawValue,
            patternFamily: pattern.family.rawValue
        )
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
            return make(id, 4, .easy, .alternatingDirectionChain, [
                a(1, 0, 3, .down),
                a(2, 3, 3, .left),
                a(3, 3, 0, .up),
                a(4, 1, 0, .right)
            ])
        case 5:
            return make(id, 4, .easy, .binaryBranch, [
                a(1, 0, 2, .left),
                a(2, 0, 0, .down),
                a(3, 3, 0, .right),
                a(4, 3, 3, .up),
                a(5, 1, 3, .left)
            ])
        case 6:
            return make(id, 4, .easy, .zigzagChain, [
                a(1, 0, 1, .right),
                a(2, 0, 3, .down),
                a(3, 2, 3, .left),
                a(4, 2, 1, .down),
                a(5, 3, 1, .left),
                a(6, 3, 0, .up)
            ])
        case 7:
            return make(id, 4, .easy, .singleBottleneck, [
                a(1, 1, 0, .down),
                a(2, 3, 0, .right),
                a(3, 3, 2, .up),
                a(4, 1, 2, .right),
                a(5, 1, 3, .down),
                a(6, 3, 3, .right)
            ])
        case 8:
            return make(id, 5, .easy, .simpleChain, [
                a(1, 0, 4, .left),
                a(2, 0, 2, .down),
                a(3, 2, 2, .left),
                a(4, 2, 0, .down),
                a(5, 4, 0, .right),
                a(6, 4, 3, .up)
            ])
        case 9:
            return make(id, 5, .easy, .brokenChain, [
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

    private static func make(_ id: Int, _ grid: Int, _ difficulty: Difficulty, _ pattern: PuzzlePattern, _ arrows: [ArrowData]) -> Level {
        Level(
            id: id,
            gridSize: grid,
            parMoves: arrows.count,
            difficulty: difficulty,
            arrows: arrows,
            seed: 9000 + id,
            archetype: pattern.rawValue,
            patternType: pattern.rawValue,
            patternFamily: pattern.family.rawValue
        )
    }

    private static func a(_ id: Int, _ row: Int, _ column: Int, _ direction: Direction) -> ArrowData {
        ArrowData(id: id, row: row, column: column, direction: direction)
    }
}
