import Foundation

struct DependencyGraph: Sendable, Equatable {
    var nodeCount: Int
    /// blocker ID → dependent IDs (blocker must be cleared first)
    var edges: [Int: [Int]]
    var decoys: Set<Int>
    var clusters: [Int: Int]
    var hubIDs: Set<Int>
    var bridgeIDs: Set<Int>
    var layoutHint: LayoutHint

    enum LayoutHint: String, Sendable, Equatable {
        case line
        case reverseLine
        case zigzag
        case staircase
        case star
        case edgeStar
        case cross
        case dual
        case triple
        case nested
        case web
        case asymmetric
        case hybrid
    }

    var nodeIDs: [Int] {
        guard nodeCount >= 1 else { return [] }
        return Array(1...nodeCount)
    }

    func dependents(of id: Int) -> [Int] {
        edges[id] ?? []
    }

    func blockers(of id: Int) -> [Int] {
        edges.compactMap { blocker, deps in deps.contains(id) ? blocker : nil }
    }

    func outDegree(_ id: Int) -> Int {
        Set(dependents(of: id)).count
    }

    func incoming(_ id: Int) -> Int {
        blockers(of: id).count
    }
}

struct GraphBuilder {
    private(set) var nodeCount = 0
    private(set) var edges: [Int: [Int]] = [:]
    var decoys: Set<Int> = []
    var clusters: [Int: Int] = [:]
    var hubIDs: Set<Int> = []
    var bridgeIDs: Set<Int> = []
    var layoutHint: DependencyGraph.LayoutHint = .line

    mutating func node(cluster: Int = 0) -> Int {
        nodeCount += 1
        clusters[nodeCount] = cluster
        return nodeCount
    }

    mutating func add(_ from: Int, _ to: Int) {
        guard from != to else { return }
        var deps = edges[from, default: []]
        if !deps.contains(to) {
            deps.append(to)
            edges[from] = deps
        }
    }

    mutating func chain(length: Int, cluster: Int = 0) -> [Int] {
        let count = max(1, length)
        let ids = (0..<count).map { _ in node(cluster: cluster) }
        for index in 0..<(ids.count - 1) {
            add(ids[index], ids[index + 1])
        }
        return ids
    }

    mutating func star(spokes: Int, cluster: Int = 0, extend: Int = 0) -> (hub: Int, spokes: [Int]) {
        let hub = node(cluster: cluster)
        hubIDs.insert(hub)
        var spokeIDs: [Int] = []
        let spokeCount = min(max(1, spokes), 3)
        for _ in 0..<spokeCount {
            var current = node(cluster: cluster)
            add(hub, current)
            spokeIDs.append(current)
            if extend > 0 {
                for _ in 0..<extend {
                    let next = node(cluster: cluster)
                    add(current, next)
                    current = next
                }
            }
        }
        return (hub, spokeIDs)
    }

    mutating func mergeOnto(parents: [Int], cluster: Int = 0) -> Int {
        let child = node(cluster: cluster)
        for parent in parents {
            add(parent, child)
        }
        return child
    }

    mutating func bridge(from a: Int, to b: Int, cluster: Int = 0) -> Int {
        let id = node(cluster: cluster)
        bridgeIDs.insert(id)
        add(a, id)
        add(id, b)
        return id
    }

    func graph() -> DependencyGraph {
        DependencyGraph(
            nodeCount: nodeCount,
            edges: edges,
            decoys: decoys,
            clusters: clusters,
            hubIDs: hubIDs,
            bridgeIDs: bridgeIDs,
            layoutHint: layoutHint
        )
    }
}

enum DependencyGraphFactory {
    static func build(
        pattern: PuzzlePattern,
        secondaries: [PuzzlePattern] = [],
        nodeCount: Int,
        rng: inout SplitMix64
    ) -> DependencyGraph {
        var builder = GraphBuilder()
        let n = max(nodeCount, minNodes(for: pattern))
        fill(pattern: pattern, count: n, rng: &rng, into: &builder)

        for secondary in secondaries.prefix(4) {
            let extra = max(3, n / max(secondaries.count + 1, 2))
            fill(pattern: secondary, count: extra, rng: &rng, into: &builder)
            if let left = builder.graph().hubIDs.sorted().last,
               let right = (1...builder.nodeCount).last,
               left != right {
                builder.add(left, right)
            }
        }

        while builder.nodeCount < n {
            let cluster = builder.clusters[builder.nodeCount] ?? 0
            let parent = Int(rng.next() % UInt64(max(builder.nodeCount, 1))) + 1
            let child = builder.node(cluster: cluster)
            if n <= 8 && rng.next() % 5 == 0 {
                builder.decoys.insert(child)
            } else if parent >= 1 && parent != child {
                builder.add(parent, child)
            }
        }

        return builder.graph()
    }

    private static func minNodes(for pattern: PuzzlePattern) -> Int {
        switch pattern.family {
        case .chain: 3
        case .branching, .bottleneck, .cross: 4
        case .cluster, .advanced: 6
        case .hybrid: 10
        }
    }

    private static func fill(pattern: PuzzlePattern, count: Int, rng: inout SplitMix64, into builder: inout GraphBuilder) {
        let n = max(3, count)
        switch pattern {
        case .simpleChain:
            builder.layoutHint = .line
            _ = builder.chain(length: n)
        case .reverseChain:
            builder.layoutHint = .reverseLine
            _ = builder.chain(length: n)
        case .longChain:
            builder.layoutHint = .line
            _ = builder.chain(length: n)
        case .doubleChain, .parallelChains:
            builder.layoutHint = .dual
            let a = max(2, n / 2)
            _ = builder.chain(length: a, cluster: 0)
            _ = builder.chain(length: n - a, cluster: 1)
        case .interlockingChains:
            builder.layoutHint = .dual
            let a = max(3, n / 2)
            let left = builder.chain(length: a, cluster: 0)
            let right = builder.chain(length: max(3, n - a), cluster: 1)
            builder.add(left[left.count / 2], right[min(1, right.count - 1)])
            if right.count > 2 && left.count > 2 {
                builder.add(right[1], left[left.count - 1])
            }
        case .zigzagChain:
            builder.layoutHint = .zigzag
            _ = builder.chain(length: n)
        case .brokenChain:
            builder.layoutHint = .line
            _ = builder.chain(length: max(2, n - 1))
            builder.decoys.insert(builder.node())
        case .alternatingDirectionChain:
            builder.layoutHint = .staircase
            _ = builder.chain(length: n)
        case .nestedChain:
            builder.layoutHint = .nested
            let inner = builder.chain(length: max(3, n / 2), cluster: 0)
            let outer = builder.chain(length: max(3, n - inner.count), cluster: 1)
            builder.add(inner[inner.count / 2], outer[0])
        case .binaryBranch:
            builder.layoutHint = .star
            let extend = n > 6 ? 1 : 0
            _ = builder.star(spokes: 2, extend: extend)
        case .tripleBranch, .wideBranch:
            builder.layoutHint = .star
            let extend = n > 10 ? 1 : 0
            _ = builder.star(spokes: 3, extend: extend)
        case .deepBranch, .branchingTree:
            builder.layoutHint = .star
            let (hub, spokes) = builder.star(spokes: 2, extend: 0)
            _ = hub
            for spoke in spokes {
                var current = spoke
                let depth = max(1, (n - 3) / max(spokes.count, 1))
                for _ in 0..<depth where builder.nodeCount < n {
                    let child = builder.node()
                    builder.add(current, child)
                    if rng.next() % 3 == 0 {
                        let extra = builder.node()
                        builder.add(current, extra)
                    }
                    current = child
                }
            }
        case .branchMerge, .convergingDependencies:
            builder.layoutHint = .star
            let (hub, spokes) = builder.star(spokes: 2)
            _ = builder.mergeOnto(parents: spokes)
            _ = hub
        case .multipleBranches:
            builder.layoutHint = .dual
            _ = builder.star(spokes: 2, cluster: 0)
            _ = builder.star(spokes: 2, cluster: 1)
        case .asymmetricBranch:
            builder.layoutHint = .asymmetric
            let (hub, spokes) = builder.star(spokes: 2)
            var current = spokes[0]
            for _ in 0..<max(2, n - 5) {
                let next = builder.node()
                builder.add(current, next)
                current = next
            }
            _ = hub
        case .singleBottleneck, .centralBottleneck:
            builder.layoutHint = .star
            _ = builder.star(spokes: min(3, max(2, n - 1)))
        case .edgeBottleneck:
            builder.layoutHint = .edgeStar
            _ = builder.star(spokes: min(3, max(2, n - 1)))
        case .doubleBottleneck, .multiStageBottleneck, .multiBottleneck:
            builder.layoutHint = .star
            let (hub1, spokes1) = builder.star(spokes: 2)
            let hub2 = builder.node()
            builder.hubIDs.insert(hub2)
            builder.add(hub1, hub2)
            for spoke in spokes1.prefix(2) {
                builder.add(hub2, spoke)
            }
            if n > builder.nodeCount {
                _ = builder.star(spokes: 2)
            }
        case .hiddenBottleneck:
            builder.layoutHint = .star
            _ = builder.star(spokes: 2)
            builder.decoys.insert(builder.node())
        case .crossLock, .horizontalVerticalLock, .intersectionLock:
            builder.layoutHint = .cross
            let h = builder.chain(length: max(3, n / 2), cluster: 0)
            let v = builder.chain(length: max(3, n - h.count), cluster: 1)
            builder.add(h[h.count / 2], v[v.count / 2])
            builder.hubIDs.insert(h[h.count / 2])
        case .doubleCross:
            builder.layoutHint = .cross
            let a = builder.chain(length: max(3, n / 3))
            let b = builder.chain(length: max(3, n / 3))
            let c = builder.chain(length: max(3, n - a.count - b.count))
            builder.add(a[a.count / 2], b[0])
            builder.add(b[b.count / 2], c[c.count / 2])
        case .crossBranch:
            builder.layoutHint = .cross
            _ = builder.star(spokes: 3)
            _ = builder.chain(length: max(3, n / 3), cluster: 1)
        case .crossBottleneck:
            builder.layoutHint = .cross
            _ = builder.star(spokes: 3)
            let line = builder.chain(length: max(3, n / 3), cluster: 1)
            if let hub = builder.hubIDs.first {
                builder.add(hub, line[0])
            }
        case .dualCluster, .isolatedClusters:
            builder.layoutHint = .dual
            _ = builder.chain(length: max(3, n / 2), cluster: 0)
            _ = builder.star(spokes: 2, cluster: 1)
        case .tripleCluster:
            builder.layoutHint = .triple
            let each = max(2, n / 3)
            _ = builder.chain(length: each, cluster: 0)
            _ = builder.star(spokes: 2, cluster: 1)
            _ = builder.chain(length: max(2, n - builder.nodeCount), cluster: 2)
        case .connectedClusters, .clusterBridge, .bridgePattern:
            builder.layoutHint = .dual
            let a = builder.chain(length: max(3, n / 2), cluster: 0)
            let b = builder.chain(length: max(3, n / 2 - 1), cluster: 1)
            _ = builder.bridge(from: a[a.count - 1], to: b[0])
        case .nestedClusters:
            builder.layoutHint = .nested
            let inner = builder.star(spokes: 2, cluster: 0)
            let outer = builder.chain(length: max(3, n / 2), cluster: 1)
            builder.add(inner.hub, outer[0])
        case .deepLock:
            builder.layoutHint = .line
            let spine = builder.chain(length: max(6, (n * 2) / 3))
            if n > spine.count {
                _ = builder.star(spokes: 2)
            }
        case .dependencyWeb:
            builder.layoutHint = .web
            let spine = builder.chain(length: max(4, n / 2))
            while builder.nodeCount < n {
                let child = builder.node()
                let parent = spine[Int(rng.next() % UInt64(spine.count))]
                builder.add(parent, child)
                if builder.nodeCount > 4 && rng.next() % 2 == 0 {
                    let other = Int(rng.next() % UInt64(builder.nodeCount - 1)) + 1
                    if other != child { builder.add(other, child) }
                }
            }
        case .divergingDependencies:
            builder.layoutHint = .star
            _ = builder.star(spokes: 3, extend: max(0, (n - 4) / 3))
        case .multiStageUnlock:
            builder.layoutHint = .star
            let stage1 = builder.star(spokes: 2)
            let stage2 = builder.star(spokes: 2)
            builder.add(stage1.spokes[0], stage2.hub)
        case .complexAsymmetric:
            builder.layoutHint = .asymmetric
            _ = builder.chain(length: max(3, n / 3), cluster: 0)
            _ = builder.star(spokes: 2, cluster: 1, extend: 1)
            if builder.nodeCount < n {
                builder.decoys.insert(builder.node(cluster: 0))
            }
        case .expertHybrid:
            builder.layoutHint = .hybrid
            _ = builder.chain(length: max(4, n / 4), cluster: 0)
            _ = builder.star(spokes: 3, cluster: 1)
            let extra = builder.chain(length: max(3, n / 4), cluster: 2)
            if let hub = builder.hubIDs.sorted().last {
                builder.add(hub, extra[0])
            }
        case .masterHybrid:
            builder.layoutHint = .hybrid
            _ = builder.chain(length: max(4, n / 5), cluster: 0)
            _ = builder.star(spokes: 3, cluster: 1)
            let c = builder.chain(length: max(3, n / 5), cluster: 2)
            _ = builder.star(spokes: 2, cluster: 3)
            if let hub = builder.hubIDs.sorted().first {
                _ = builder.bridge(from: hub, to: c[0])
            }
        }
    }
}
