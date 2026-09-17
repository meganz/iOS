import Foundation
import MEGADomain
import MEGARepo
import MEGASwift
import Testing

@Suite("FileSystemRepository Tests - Removal and directory listing against a real temporary directory.")
struct FileSystemRepositoryTests {

    private let sut = FileSystemRepository.sharedRepo

    // MARK: - removeItem

    /// The export flow clears its temporary folder from a task that has just been cancelled, so a removal
    /// that gives up on cancellation would leave the folder behind and only log that it failed.
    @Test("an item is removed even when the calling task is already cancelled")
    func removeItem_whenCallingTaskIsCancelled_stillRemovesTheItem() async throws {
        let folder = try makeTemporaryFolder()
        let file = try makeFile(named: "MyFile", in: folder)

        let task = Task<Void, any Error> {
            // Held until the cancellation has actually landed, so the removal below is made from a task
            // that is cancelled rather than from one that merely will be.
            while !Task.isCancelled {
                await Task.yield()
            }
            try await sut.removeItem(at: file)
        }
        task.cancel()
        try await task.value

        #expect(!FileManager.default.fileExists(atPath: file.path))
    }

    /// Why the removal above is built on a plain continuation: `withAsyncThrowingValue` gives up before it
    /// calls its operation at all, so a removal built on it does not touch the filesystem when the calling
    /// task is cancelled — it only reports that it failed.
    @Test("withAsyncThrowingValue refuses to run at all once the calling task is cancelled")
    func withAsyncThrowingValue_whenCancelled_throwsWithoutRunning() async {
        let task = Task<Void, any Error> {
            while !Task.isCancelled {
                await Task.yield()
            }
            try await withAsyncThrowingValue { (completion: @Sendable @escaping (Result<Void, any Error>) -> Void) in
                completion(.success(()))
            }
        }
        task.cancel()

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }

    @Test("removing a whole folder takes everything under it")
    func removeItem_folder_removesItsContents() async throws {
        let folder = try makeTemporaryFolder()
        _ = try makeFile(named: "MyFile", in: folder)

        try await sut.removeItem(at: folder)

        #expect(!FileManager.default.fileExists(atPath: folder.path))
    }

    @Test("removing something that is not there throws")
    func removeItem_missingItem_throws() async throws {
        let missing = try makeTemporaryFolder().appendingPathComponent("NotThere")

        await #expect(throws: (any Error).self) {
            try await sut.removeItem(at: missing)
        }
    }

    // MARK: - contentsOfDirectory

    /// One URL per item and no deeper: an export hands a folder over as one thing, however many files are
    /// inside it.
    @Test("the top level of a directory is listed, and nothing below it")
    func contentsOfDirectory_listsTopLevelItemsOnly() async throws {
        let folder = try makeTemporaryFolder()
        let file = try makeFile(named: "MyFile", in: folder)
        let child = folder.appendingPathComponent("Child", isDirectory: true)
        try FileManager.default.createDirectory(at: child, withIntermediateDirectories: true)
        _ = try makeFile(named: "Buried", in: child)

        let contents = await sut.contentsOfDirectory(at: folder)

        #expect(Set(contents.map(\.lastPathComponent)) == [file.lastPathComponent, "Child"])
    }

    /// Said out loud because the export reads this list straight into the share sheet: the SDK writes a
    /// download still in progress as a hidden `.getxfer...mega` file in the folder it is downloading into,
    /// and a caller that must not offer those has to drop them itself.
    @Test("hidden items are listed like any other")
    func contentsOfDirectory_includesHiddenItems() async throws {
        let folder = try makeTemporaryFolder()
        let hidden = try makeFile(named: ".getxfer.1.2.mega", in: folder)

        let contents = await sut.contentsOfDirectory(at: folder)

        #expect(contents.map(\.lastPathComponent) == [hidden.lastPathComponent])
    }

    @Test("an empty directory comes back as no items")
    func contentsOfDirectory_emptyDirectory_returnsNothing() async throws {
        let folder = try makeTemporaryFolder()

        let contents = await sut.contentsOfDirectory(at: folder)

        #expect(contents.isEmpty)
    }

    /// The signature has nowhere to report a failure, so a URL that cannot be listed is indistinguishable
    /// from a folder with nothing in it. A caller reading this as "nothing was produced" is reading it the
    /// only way it can be read.
    @Test("a URL that is not a directory comes back as no items rather than throwing")
    func contentsOfDirectory_notADirectory_returnsNothing() async throws {
        let file = try makeFile(named: "MyFile", in: try makeTemporaryFolder())

        let contents = await sut.contentsOfDirectory(at: file)

        #expect(contents.isEmpty)
    }

    // MARK: - Helpers

    /// A directory of this test's own, so tests running alongside each other cannot see each other's files.
    private func makeTemporaryFolder() throws -> URL {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("FileSystemRepositoryTests", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    private func makeFile(named name: String, in folder: URL) throws -> URL {
        let file = folder.appendingPathComponent(name)
        try Data("content".utf8).write(to: file)
        return file
    }
}
