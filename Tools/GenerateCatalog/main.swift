import Foundation

@main
enum GenerateCatalogMain {
    static func main() throws {
        let output = CommandLine.arguments.count > 1
            ? CommandLine.arguments[1]
            : "Pathloom/Resources/Levels.json"
        let data = try LevelCatalogBuilder.jsonData()
        let url = URL(fileURLWithPath: output)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url)
        let catalog = try JSONDecoder().decode(LevelCatalog.self, from: data)
        print(LevelValidator.report(for: catalog.levels))
        print("Wrote \(catalog.levels.count) levels to \(output)")
    }
}
