@testable import MEGA
import MEGADomain
import MEGARepo
import Testing
import UIKit

@Suite("OfflineThumbnailCache Tests")
@MainActor
struct OfflineThumbnailCacheTests {

    @Suite("Generating")
    @MainActor
    struct Generating {
        /// The point of the cache: once generated, a cell being re-configured picks the thumbnail up
        /// in the same layout pass instead of showing the file type placeholder again — that
        /// placeholder in between is the flashing reported in IOS-10912.
        @Test("serves a generated thumbnail synchronously afterwards")
        func servesSynchronouslyOnceGenerated() async throws {
            let harness = try Harness()

            #expect(harness.sut.image(for: harness.fileURL) == nil, "nothing generated yet")
            _ = await harness.sut.thumbnail(for: harness.fileURL)

            #expect(harness.sut.image(for: harness.fileURL) != nil)
        }

        @Test("generates once and serves the rest from the cache")
        func generatesOnce() async throws {
            let harness = try Harness()

            _ = await harness.sut.thumbnail(for: harness.fileURL)
            _ = await harness.sut.thumbnail(for: harness.fileURL)

            #expect(harness.generatorCallCount == 1)
        }

        /// The Offline list reloads on every download completion, so the same URL is asked for by
        /// several cells at once.
        @Test("coalesces concurrent requests for the same file into one generation")
        func coalescesConcurrentRequests() async throws {
            let harness = try Harness()

            async let first = harness.sut.thumbnail(for: harness.fileURL)
            async let second = harness.sut.thumbnail(for: harness.fileURL)
            _ = await (first, second)

            #expect(harness.generatorCallCount == 1)
        }

        @Test("caches nothing when no thumbnail could be produced")
        func doesNotCacheAFailedGeneration() async throws {
            let harness = try Harness(stubbedThumbnail: nil)

            _ = await harness.sut.thumbnail(for: harness.fileURL)

            #expect(harness.sut.image(for: harness.fileURL) == nil)
        }

        @Test("is a no-op for anything that is not a file on disk")
        func ignoresNonFileURLs() async throws {
            let harness = try Harness()
            let remoteURL = try #require(URL(string: "https://mega.nz/file.jpg"))

            let thumbnail = await harness.sut.thumbnail(for: remoteURL)

            #expect(thumbnail == nil)
            #expect(harness.generatorCallCount == 0)
        }

        /// A file replaced by a new download keeps its path, so the modification date is what stops
        /// the previous thumbnail being served for the new contents.
        @Test("regenerates once the file has been replaced")
        func regeneratesAfterTheFileChanges() async throws {
            let harness = try Harness()
            _ = await harness.sut.thumbnail(for: harness.fileURL)

            try harness.rewriteFile()

            #expect(harness.sut.image(for: harness.fileURL) == nil, "the entry for the old contents must not match")
            _ = await harness.sut.thumbnail(for: harness.fileURL)
            #expect(harness.generatorCallCount == 2)
        }
    }

    @Suite("Emptying")
    @MainActor
    struct Emptying {
        /// Logging out deletes the Offline directory, so everything cached describes a file that is
        /// gone — and would otherwise stay in memory until a memory warning arrived.
        @Test("drops everything when the account logs out")
        func clearsOnLogout() async throws {
            let harness = try Harness()
            _ = await harness.sut.thumbnail(for: harness.fileURL)

            harness.post(.accountDidLogout)

            await waitUntil { harness.isEmpty }
            #expect(harness.isEmpty)
        }

        @Test("drops everything under memory pressure")
        func clearsOnMemoryWarning() async throws {
            let harness = try Harness()
            _ = await harness.sut.thumbnail(for: harness.fileURL)

            harness.post(UIApplication.didReceiveMemoryWarningNotification)

            await waitUntil { harness.isEmpty }
            #expect(harness.isEmpty)
        }

        @Test("generates again after being emptied")
        func regeneratesAfterClearing() async throws {
            let harness = try Harness()
            _ = await harness.sut.thumbnail(for: harness.fileURL)

            harness.sut.removeAll()
            _ = await harness.sut.thumbnail(for: harness.fileURL)

            #expect(harness.generatorCallCount == 2)
        }
    }
}

// MARK: - Harness

@MainActor
private final class Harness {
    let sut: OfflineThumbnailCache
    let fileURL: URL

    private let notificationCenter = NotificationCenter()
    private let directory: URL
    private let generator: MockFileAttributeGenerator

    /// `OfflineThumbnailCache` keys on the file's modification date, so the file has to exist —
    /// only the thumbnail generation itself is stubbed.
    init(stubbedThumbnail: UIImage? = UIImage(systemName: "doc")) throws {
        generator = MockFileAttributeGenerator(stubbedThumbnail: stubbedThumbnail)
        directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("OfflineThumbnailCacheTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appendingPathComponent("photo.jpg")
        try Data("first".utf8).write(to: fileURL)

        sut = OfflineThumbnailCache(
            notificationCenter: notificationCenter,
            makeThumbnailGenerator: { [generator] _ in generator }
        )
    }

    deinit {
        try? FileManager.default.removeItem(at: directory)
    }

    var generatorCallCount: Int { generator.requestThumbnailCallCount }

    /// Rewrites with a later modification date, standing in for the file being replaced by a new
    /// download. Set explicitly because two writes in the same test can land on the same timestamp.
    func rewriteFile() throws {
        try Data("second".utf8).write(to: fileURL)
        try FileManager.default.setAttributes(
            [.modificationDate: Date().addingTimeInterval(60)],
            ofItemAtPath: fileURL.path
        )
    }

    func post(_ name: Notification.Name) {
        notificationCenter.post(name: name, object: nil)
    }

    var isEmpty: Bool { sut.image(for: fileURL) == nil }
}

/// The observers are registered on `OperationQueue.main`, so posting only enqueues them and there
/// is no ordering contract between that queue and the main actor's executor — neither yielding a
/// fixed number of turns nor sleeping a fixed time proves delivery happened. Polling for the effect
/// does: it returns as soon as the observer has run, and gives up after a second so a regression
/// fails on the assertion that follows rather than hanging the suite.
@MainActor
private func waitUntil(timeout: Duration = .seconds(1), _ condition: () -> Bool) async {
    let deadline = ContinuousClock.now + timeout
    while !condition(), ContinuousClock.now < deadline {
        try? await Task.sleep(for: .milliseconds(1))
    }
}

private final class MockFileAttributeGenerator: FileAttributeGeneratorProtocol, @unchecked Sendable {
    private(set) var requestThumbnailCallCount = 0
    private let stubbedThumbnail: UIImage?

    init(stubbedThumbnail: UIImage?) {
        self.stubbedThumbnail = stubbedThumbnail
    }

    func createThumbnail(at destinationURL: URL) async -> Bool { false }

    func createPreview(at destinationURL: URL) async -> Bool { false }

    func requestThumbnail() async -> UIImage? {
        requestThumbnailCallCount += 1
        return stubbedThumbnail
    }
}
