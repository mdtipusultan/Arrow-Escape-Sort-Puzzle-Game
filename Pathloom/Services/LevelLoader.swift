import Foundation

enum LevelLoaderError: Error, Equatable {
    case missingResource
    case decodingFailed
    case emptyCatalog
}

protocol LevelLoading: Sendable {
    func loadCatalog() throws -> LevelCatalog
    func level(id: Int) throws -> Level
}

struct LevelLoader: LevelLoading {
    private let bundle: Bundle
    private let fileName: String

    init(bundle: Bundle = .main, fileName: String = "Levels") {
        self.bundle = bundle
        self.fileName = fileName
    }

    func loadCatalog() throws -> LevelCatalog {
        guard let url = bundle.url(forResource: fileName, withExtension: "json") else {
            throw LevelLoaderError.missingResource
        }
        do {
            let data = try Data(contentsOf: url)
            let catalog = try JSONDecoder().decode(LevelCatalog.self, from: data)
            if catalog.levels.isEmpty {
                throw LevelLoaderError.emptyCatalog
            }
            return catalog
        } catch let error as LevelLoaderError {
            throw error
        } catch {
            throw LevelLoaderError.decodingFailed
        }
    }

    func level(id: Int) throws -> Level {
        let catalog = try loadCatalog()
        guard let match = catalog.levels.first(where: { $0.id == id }) else {
            throw LevelLoaderError.emptyCatalog
        }
        return match
    }

    static func fallbackTutorialLevel() -> Level {
        Level(
            id: 1,
            gridSize: 3,
            parMoves: 1,
            difficulty: .tutorial,
            arrows: [
                ArrowData(id: 1, row: 1, column: 0, direction: .right)
            ],
            seed: 1
        )
    }

    static func totalLevels(in catalog: LevelCatalog) -> Int {
        max(catalog.levels.count, 1)
    }
}
