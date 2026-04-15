import Foundation
import Testing
@testable import MediaImport

@Suite("FileStagingService")
struct FileStagingServiceTests {
    let sut = FileStagingService()

    private func makeTempDirectory() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func createTempFile(named name: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent(name)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("test".utf8).write(to: url)
        return url
    }

    @Test("Stages file to destination directory")
    func stagesFile() throws {
        let source = try createTempFile(named: "photo.heic")
        let destination = try makeTempDirectory()

        let result = try sut.stageFile(from: source, to: destination)

        #expect(FileManager.default.fileExists(atPath: result.path))
        #expect(result.pathExtension == "heic")
        #expect(result.deletingLastPathComponent().path == destination.path)
    }

    @Test("Generates unique name when file exists")
    func uniqueName() throws {
        let destination = try makeTempDirectory()

        let source1 = try createTempFile(named: "photo.heic")
        let result1 = try sut.stageFile(from: source1, to: destination)

        let source2 = try createTempFile(named: "photo.heic")
        let result2 = try sut.stageFile(from: source2, to: destination)

        #expect(result1 != result2)
        #expect(FileManager.default.fileExists(atPath: result1.path))
        #expect(FileManager.default.fileExists(atPath: result2.path))
    }

    @Test("Creates destination directory if needed")
    func createsDirectory() throws {
        let source = try createTempFile(named: "photo.heic")
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("nested")

        let result = try sut.stageFile(from: source, to: destination)

        #expect(FileManager.default.fileExists(atPath: result.path))
    }

    @Test("Preserves file content after staging")
    func preservesContent() throws {
        let source = try createTempFile(named: "data.bin")
        let destination = try makeTempDirectory()

        let result = try sut.stageFile(from: source, to: destination)

        let content = try Data(contentsOf: result)
        #expect(content == Data("test".utf8))
    }

    @Test("Stages file without extension")
    func noExtension() throws {
        let source = try createTempFile(named: "noext")
        let destination = try makeTempDirectory()

        let result = try sut.stageFile(from: source, to: destination)

        #expect(FileManager.default.fileExists(atPath: result.path))
        // Source has no extension, so the staged name is the formatted date only
        // (e.g. "2026-04-09 13.05.29") — no added extension suffix
        #expect(!result.lastPathComponent.hasSuffix(".heic"))
        #expect(!result.lastPathComponent.hasSuffix(".jpg"))
    }

    @Test("Generates multiple unique names for collisions")
    func multipleCollisions() throws {
        let destination = try makeTempDirectory()

        var results: [URL] = []
        for _ in 0..<5 {
            let source = try createTempFile(named: "photo.jpg")
            let result = try sut.stageFile(from: source, to: destination)
            results.append(result)
        }

        #expect(Set(results).count == 5)
        for url in results {
            #expect(FileManager.default.fileExists(atPath: url.path))
        }
    }
}
