import FileProvider
import Foundation
import MEGAPickerFileProviderDomain
@testable import MEGAPickerFileProviderRepo
import Testing

final class FileProviderSnapshotRepositoryTests {
    private let directoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    private let folder = NSFileProviderItemIdentifier("folder")

    deinit {
        try? FileManager.default.removeItem(at: directoryURL)
    }

    @Test
    func snapshot_ofAContainerNeverSaved_isNil() async throws {
        let sut = makeSUT()

        #expect(try await sut.snapshot(of: folder) == nil)
    }

    @Test
    func snapshot_givesBackWhatWasSaved() async throws {
        let sut = makeSUT()
        let snapshot = FileProviderSnapshotEntity(versionHashes: [
            NSFileProviderItemIdentifier("a-B_9"): 0,
            NSFileProviderItemIdentifier("b"): .max,
            NSFileProviderItemIdentifier("c"): 0x0123_4567_89ab_cdef,
            NSFileProviderItemIdentifier("文件 ü"): 1
        ])

        try await save(snapshot, of: folder, in: sut)

        #expect(try await sut.snapshot(of: folder) == snapshot)
    }

    @Test
    func snapshot_ofAnEmptyFolder_isEmptyRatherThanNil() async throws {
        let sut = makeSUT()

        try await save(FileProviderSnapshotEntity(), of: folder, in: sut)

        #expect(try await sut.snapshot(of: folder) == FileProviderSnapshotEntity())
    }

    @Test
    func updateSnapshot_startsFromTheSavedSnapshot() async throws {
        let sut = makeSUT()
        try await save(FileProviderSnapshotEntity(versionHashes: [NSFileProviderItemIdentifier("a"): 1]), of: folder, in: sut)

        try await sut.updateSnapshot(of: folder) { $0?.versionHashes[NSFileProviderItemIdentifier("b")] = 2 }

        let expected = FileProviderSnapshotEntity(versionHashes: [NSFileProviderItemIdentifier("a"): 1, NSFileProviderItemIdentifier("b"): 2])
        #expect(try await sut.snapshot(of: folder) == expected)
    }

    @Test
    func updateSnapshot_toNil_removesTheSnapshot() async throws {
        let sut = makeSUT()
        try await save(FileProviderSnapshotEntity(), of: folder, in: sut)

        try await sut.updateSnapshot(of: folder) { $0 = nil }

        #expect(try await sut.snapshot(of: folder) == nil)
        #expect(try await sut.containerIdentifiers() == [])
    }

    @Test
    func updateSnapshot_leavingNoSnapshot_createsNone() async throws {
        let sut = makeSUT()

        try await sut.updateSnapshot(of: folder) { _ in }

        #expect(try await sut.containerIdentifiers() == [])
    }

    @Test
    func updateSnapshot_concurrentUpdates_allLand() async throws {
        let sut = makeSUT()
        let identifiers = (0..<50).map { NSFileProviderItemIdentifier("child\($0)") }

        try await withThrowingTaskGroup(of: Void.self) { group in
            for identifier in identifiers {
                group.addTask {
                    try await sut.updateSnapshot(of: .rootContainer) { snapshot in
                        var updated = snapshot ?? FileProviderSnapshotEntity()
                        updated.versionHashes[identifier] = 1
                        snapshot = updated
                    }
                }
            }
            try await group.waitForAll()
        }

        #expect(try await sut.snapshot(of: .rootContainer)?.versionHashes.count == identifiers.count)
    }

    @Test
    func snapshot_ofADamagedFile_isEmpty() async throws {
        let sut = makeSUT()
        try await save(FileProviderSnapshotEntity(versionHashes: [NSFileProviderItemIdentifier("a"): 1]), of: folder, in: sut)
        let fileURL = try snapshotFileURL()
        try Data(contentsOf: fileURL).dropLast().write(to: fileURL)

        #expect(try await sut.snapshot(of: folder) == FileProviderSnapshotEntity())
    }

    @Test
    func snapshot_ofAFileInAnUnknownFormat_isEmpty() async throws {
        let sut = makeSUT()
        try await save(FileProviderSnapshotEntity(versionHashes: [NSFileProviderItemIdentifier("a"): 1]), of: folder, in: sut)
        let fileURL = try snapshotFileURL()
        var data = try Data(contentsOf: fileURL)
        data[data.startIndex] = 99
        try data.write(to: fileURL)

        #expect(try await sut.snapshot(of: folder) == FileProviderSnapshotEntity())
    }

    @Test
    func removeSnapshot_leavesNoSnapshot() async throws {
        let sut = makeSUT()
        try await save(FileProviderSnapshotEntity(), of: folder, in: sut)

        try await sut.removeSnapshot(of: folder)
        try await sut.removeSnapshot(of: NSFileProviderItemIdentifier("never saved"))

        #expect(try await sut.snapshot(of: folder) == nil)
    }

    @Test
    func containerIdentifiers_areTheContainersWithASnapshot() async throws {
        let sut = makeSUT()
        let identifiers: Set<NSFileProviderItemIdentifier> = [
            .rootContainer,
            .trashContainer,
            NSFileProviderItemIdentifier("a-B_9"),
            NSFileProviderItemIdentifier("with.dot/slash"),
            NSFileProviderItemIdentifier("文件 ü")
        ]
        for identifier in identifiers {
            try await save(FileProviderSnapshotEntity(), of: identifier, in: sut)
        }

        #expect(Set(try await sut.containerIdentifiers()) == identifiers)
    }

    @Test
    func containerIdentifiers_withoutAnySnapshot_isEmpty() async throws {
        let sut = makeSUT()

        #expect(try await sut.containerIdentifiers() == [])
    }

    // MARK: - Helpers

    private func makeSUT() -> FileProviderSnapshotRepository {
        FileProviderSnapshotRepository(directoryURL: directoryURL)
    }

    private func save(
        _ snapshot: FileProviderSnapshotEntity,
        of containerIdentifier: NSFileProviderItemIdentifier,
        in sut: FileProviderSnapshotRepository
    ) async throws {
        try await sut.updateSnapshot(of: containerIdentifier) { $0 = snapshot }
    }

    /// The only snapshot file in the directory.
    private func snapshotFileURL() throws -> URL {
        let fileURL = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil).first
        return try #require(fileURL)
    }
}
