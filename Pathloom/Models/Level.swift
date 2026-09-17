import Foundation

enum Difficulty: String, Codable, Sendable, CaseIterable {
    case tutorial
    case easy
    case medium
    case hard
    case veryHard
    case expert
    case challenge
    case master

    var displayName: String {
        switch self {
        case .tutorial: "Tutorial"
        case .easy: "Easy"
        case .medium: "Medium"
        case .hard: "Hard"
        case .veryHard: "Very Hard"
        case .expert: "Expert"
        case .challenge: "Challenge"
        case .master: "Master"
        }
    }
}

struct Level: Identifiable, Codable, Hashable, Sendable {
    let id: Int
    let gridSize: Int
    let parMoves: Int
    let difficulty: Difficulty
    let arrows: [ArrowData]
    let seed: Int?
    let archetype: String?
    let patternType: String?
    let patternFamily: String?
    let difficultyScore: Double?
    let solutionDepth: Int?
    let branchingFactor: Int?
    let bottleneckCount: Int?
    let clusterCount: Int?

    var arrowCount: Int { arrows.count }
    var resolvedPatternType: String { patternType ?? archetype ?? "unknown" }

    init(
        id: Int,
        gridSize: Int,
        parMoves: Int,
        difficulty: Difficulty,
        arrows: [ArrowData],
        seed: Int? = nil,
        archetype: String? = nil,
        patternType: String? = nil,
        patternFamily: String? = nil,
        difficultyScore: Double? = nil,
        solutionDepth: Int? = nil,
        branchingFactor: Int? = nil,
        bottleneckCount: Int? = nil,
        clusterCount: Int? = nil
    ) {
        self.id = id
        self.gridSize = gridSize
        self.parMoves = parMoves
        self.difficulty = difficulty
        self.arrows = arrows
        self.seed = seed
        self.archetype = archetype ?? patternType
        self.patternType = patternType ?? archetype
        self.patternFamily = patternFamily
        self.difficultyScore = difficultyScore
        self.solutionDepth = solutionDepth
        self.branchingFactor = branchingFactor
        self.bottleneckCount = bottleneckCount
        self.clusterCount = clusterCount
    }

    enum CodingKeys: String, CodingKey {
        case id, gridSize, parMoves, difficulty, arrows, seed
        case archetype, patternType, patternFamily
        case difficultyScore, solutionDepth
        case branchingFactor, bottleneckCount, clusterCount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        gridSize = try container.decode(Int.self, forKey: .gridSize)
        parMoves = try container.decode(Int.self, forKey: .parMoves)
        difficulty = try container.decode(Difficulty.self, forKey: .difficulty)
        arrows = try container.decode([ArrowData].self, forKey: .arrows)
        seed = try container.decodeIfPresent(Int.self, forKey: .seed)
        let decodedArchetype = try container.decodeIfPresent(String.self, forKey: .archetype)
        let decodedPattern = try container.decodeIfPresent(String.self, forKey: .patternType)
        archetype = decodedArchetype ?? decodedPattern
        patternType = decodedPattern ?? decodedArchetype
        patternFamily = try container.decodeIfPresent(String.self, forKey: .patternFamily)
        difficultyScore = try container.decodeIfPresent(Double.self, forKey: .difficultyScore)
        solutionDepth = try container.decodeIfPresent(Int.self, forKey: .solutionDepth)
        branchingFactor = try container.decodeIfPresent(Int.self, forKey: .branchingFactor)
        bottleneckCount = try container.decodeIfPresent(Int.self, forKey: .bottleneckCount)
        clusterCount = try container.decodeIfPresent(Int.self, forKey: .clusterCount)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(gridSize, forKey: .gridSize)
        try container.encode(parMoves, forKey: .parMoves)
        try container.encode(difficulty, forKey: .difficulty)
        try container.encode(arrows, forKey: .arrows)
        try container.encodeIfPresent(seed, forKey: .seed)
        try container.encodeIfPresent(archetype, forKey: .archetype)
        try container.encodeIfPresent(patternType, forKey: .patternType)
        try container.encodeIfPresent(patternFamily, forKey: .patternFamily)
        try container.encodeIfPresent(difficultyScore, forKey: .difficultyScore)
        try container.encodeIfPresent(solutionDepth, forKey: .solutionDepth)
        try container.encodeIfPresent(branchingFactor, forKey: .branchingFactor)
        try container.encodeIfPresent(bottleneckCount, forKey: .bottleneckCount)
        try container.encodeIfPresent(clusterCount, forKey: .clusterCount)
    }
}

struct LevelCatalog: Codable, Sendable {
    let levels: [Level]
}
