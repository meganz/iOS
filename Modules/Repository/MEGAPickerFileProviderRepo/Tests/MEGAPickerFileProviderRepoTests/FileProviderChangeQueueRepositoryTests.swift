import FileProvider
import Foundation
import MEGAPickerFileProviderDomain
@testable import MEGAPickerFileProviderRepo
import Testing

final class FileProviderChangeQueueRepositoryTests {
    private let directoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)

    deinit {
        try? FileManager.default.removeItem(at: directoryURL)
    }

    @Test
    func changes_sinceTheAnchorOfAnEmptyQueue_areTheAppendedOnes() async throws {
        let sut = makeSUT()
        let anchor = try await sut.currentAnchor()
        let changes = [change("a"), change("b", in: .rootContainer)]

        try await sut.append(changes)

        let batch = try await sut.changes(since: anchor, limit: 10)
        let currentAnchor = try await sut.currentAnchor()
        #expect(batch.changes == changes)
        #expect(batch.hasMore == false)
        #expect(batch.nextAnchor == currentAnchor)
    }

    @Test
    func changes_sinceTheCurrentAnchor_areNone() async throws {
        let sut = makeSUT()
        try await sut.append([change("a")])

        let batch = try await sut.changes(since: try await sut.currentAnchor(), limit: 10)

        #expect(batch.changes == [])
        #expect(batch.hasMore == false)
    }

    @Test
    func changes_returnAtMostTheLimitAndContinueFromTheNextAnchor() async throws {
        let sut = makeSUT()
        let anchor = try await sut.currentAnchor()
        try await sut.append([change("a"), change("b"), change("c")])

        let first = try await sut.changes(since: anchor, limit: 2)
        let second = try await sut.changes(since: first.nextAnchor, limit: 2)

        #expect(first.changes == [change("a"), change("b")])
        #expect(first.hasMore)
        #expect(second.changes == [change("c")])
        #expect(second.hasMore == false)
    }

    @Test
    func changes_ignoreALineThatIsNotFinished() async throws {
        let sut = makeSUT()
        let anchor = try await sut.currentAnchor()
        try await sut.append([change("a")])
        try appendRawText("b")

        let batch = try await sut.changes(since: anchor, limit: 10)

        let currentAnchor = try await sut.currentAnchor()
        #expect(batch.changes == [change("a")])
        #expect(batch.nextAnchor == currentAnchor)
    }

    @Test
    func append_afterALineCutShort_keepsTheNewChangesReadable() async throws {
        let sut = makeSUT()
        let anchor = try await sut.currentAnchor()
        try await sut.append([change("a")])
        try appendRawText("cut")

        try await sut.append([change("b")])

        let batch = try await sut.changes(since: anchor, limit: 10)
        #expect(batch.changes == [change("a"), change("b")])
    }

    @Test
    func changes_continueIntoTheNextGeneration() async throws {
        let sut = makeSUT(maxFileSize: 1)
        let anchor = try await sut.currentAnchor()
        try await sut.append([change("a")])
        try await sut.append([change("b")])

        let batch = try await sut.changes(since: anchor, limit: 10)

        let currentAnchor = try await sut.currentAnchor()
        #expect(batch.changes == [change("a"), change("b")])
        #expect(batch.nextAnchor == currentAnchor)
        #expect(currentAnchor.generation == 1)
    }

    @Test
    func changes_sinceAGenerationThatWasDeleted_throwAnchorExpired() async throws {
        let sut = makeSUT(maxFileSize: 1)
        try await sut.append([change("a")])
        let anchor = try await sut.currentAnchor()
        try await sut.append([change("b")])
        try await sut.append([change("c")])

        await expectAnchorExpired(sut, anchor: anchor)
    }

    @Test
    func changes_sinceAnAnchorOfAnotherStore_throwAnchorExpired() async throws {
        let sut = makeSUT()
        let anchor = try await sut.currentAnchor()
        try FileManager.default.removeItem(at: directoryURL)

        await expectAnchorExpired(sut, anchor: anchor)
    }

    @Test
    func changes_sinceAnOffsetPastTheEnd_throwAnchorExpired() async throws {
        let sut = makeSUT()
        try await sut.append([change("a")])
        let anchor = try await sut.currentAnchor()

        await expectAnchorExpired(sut, anchor: anchor.moved(to: anchor.offset + 1))
    }

    @Test
    func changes_sinceANegativeOffset_throwAnchorExpired() async throws {
        let sut = makeSUT()
        let anchor = try await sut.currentAnchor()
        try await sut.append([change("a")])

        await expectAnchorExpired(sut, anchor: anchor.moved(to: -1))
    }

    @Test
    func changes_sinceAnOffsetInTheMiddleOfALine_throwAnchorExpired() async throws {
        let sut = makeSUT()
        let anchor = try await sut.currentAnchor()
        try await sut.append([change("a")])

        await expectAnchorExpired(sut, anchor: anchor.moved(to: 1))
    }

    @Test
    func currentAnchor_staysTheSameWithoutAppends() async throws {
        let sut = makeSUT()

        let first = try await sut.currentAnchor()
        let second = try await sut.currentAnchor()

        #expect(first == second)
    }

    @Test
    func currentAnchor_withADamagedStoreID_expiresTheAnchorsHandedOut() async throws {
        let sut = makeSUT()
        let anchor = try await sut.currentAnchor()
        try Data("damaged".utf8).write(to: directoryURL.appendingPathComponent("store-id"))

        let currentAnchor = try await sut.currentAnchor()

        #expect(currentAnchor.storeID != anchor.storeID)
        await expectAnchorExpired(sut, anchor: anchor)
    }

    @Test
    func currentAnchor_withAStoreIDThatCannotBeRead_throwsAndKeepsIt() async throws {
        let sut = makeSUT()
        let storeIDURL = directoryURL.appendingPathComponent("store-id")
        // A directory exists but cannot be read as a file.
        try FileManager.default.createDirectory(at: storeIDURL, withIntermediateDirectories: true)

        await #expect(throws: (any Error).self) {
            try await sut.currentAnchor()
        }
        var isDirectory: ObjCBool = false
        #expect(FileManager.default.fileExists(atPath: storeIDURL.path, isDirectory: &isDirectory) && isDirectory.boolValue)
    }

    // MARK: - Helpers

    private func makeSUT(maxFileSize: Int = 512 * 1024) -> FileProviderChangeQueueRepository {
        FileProviderChangeQueueRepository(directoryURL: directoryURL, maxFileSize: maxFileSize)
    }

    private func change(
        _ identifier: String,
        in folderIdentifier: NSFileProviderItemIdentifier = NSFileProviderItemIdentifier("folder")
    ) -> FileProviderChangeEntity {
        FileProviderChangeEntity(identifier: NSFileProviderItemIdentifier(identifier), folderIdentifier: folderIdentifier)
    }

    /// Writes to the queue file the way a crash in the middle of an append would leave it.
    private func appendRawText(_ text: String) throws {
        let fileHandle = try FileHandle(forWritingTo: directoryURL.appendingPathComponent("queue-0"))
        defer { try? fileHandle.close() }
        try fileHandle.seekToEnd()
        try fileHandle.write(contentsOf: Data(text.utf8))
    }

    private func expectAnchorExpired(
        _ sut: FileProviderChangeQueueRepository,
        anchor: FileProviderChangeAnchorEntity,
        sourceLocation: SourceLocation = #_sourceLocation
    ) async {
        await #expect(throws: FileProviderChangeQueueErrorEntity.anchorExpired, sourceLocation: sourceLocation) {
            try await sut.changes(since: anchor, limit: 10)
        }
    }
}

private extension FileProviderChangeAnchorEntity {
    func moved(to offset: Int) -> FileProviderChangeAnchorEntity {
        FileProviderChangeAnchorEntity(storeID: storeID, generation: generation, offset: offset)
    }
}
