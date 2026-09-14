import Foundation

enum Difficulty: String, Codable, Sendable, CaseIterable {
    case tutorial
    case easy
    case medium
    case hard
    case veryHard
    case expert
    case challenge

    var displayName: String {
        switch self {
        case .tutorial: "Tutorial"
        case .easy: "Easy"
        case .medium: "Medium"
        case .hard: "Hard"
        case .veryHard: "Very Hard"
        case .expert: "Expert"
        case .challenge: "Challenge"
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
    let difficultyScore: Double?
    let solutionDepth: Int?

    var arrowCount: Int { arrows.count }

    init(
        id: Int,
        gridSize: Int,
        parMoves: Int,
        difficulty: Difficulty,
        arrows: [ArrowData],
        seed: Int? = nil,
        archetype: String? = nil,
        difficultyScore: Double? = nil,
        solutionDepth: Int? = nil
    ) {
        self.id = id
        self.gridSize = gridSize
        self.parMoves = parMoves
        self.difficulty = difficulty
        self.arrows = arrows
        self.seed = seed
        self.archetype = archetype
        self.difficultyScore = difficultyScore
        self.solutionDepth = solutionDepth
    }

    enum CodingKeys: String, CodingKey {
        case id, gridSize, parMoves, difficulty, arrows, seed
        case archetype, difficultyScore, solutionDepth
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        gridSize = try container.decode(Int.self, forKey: .gridSize)
        parMoves = try container.decode(Int.self, forKey: .parMoves)
        difficulty = try container.decode(Difficulty.self, forKey: .difficulty)
        arrows = try container.decode([ArrowData].self, forKey: .arrows)
        seed = try container.decodeIfPresent(Int.self, forKey: .seed)
        archetype = try container.decodeIfPresent(String.self, forKey: .archetype)
        difficultyScore = try container.decodeIfPresent(Double.self, forKey: .difficultyScore)
        solutionDepth = try container.decodeIfPresent(Int.self, forKey: .solutionDepth)
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
        try container.encodeIfPresent(difficultyScore, forKey: .difficultyScore)
        try container.encodeIfPresent(solutionDepth, forKey: .solutionDepth)
    }
}

struct LevelCatalog: Codable, Sendable {
    let levels: [Level]
}
