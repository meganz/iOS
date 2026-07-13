import Foundation
import MEGADomain
import MEGADomainMock
import MEGARepo
import Testing
@testable import Transfer
import UIKit

@MainActor
@Suite("TransferThumbnailLoader")
struct TransferThumbnailLoaderTests {

    // MARK: - Downloads

    @Test func downloadWithCachedSDKThumbnailReturnsDecodedImage() async throws {
        let thumbnailURL = try writeTempImage()
        let sut = makeSUT(
            thumbnailUseCase: MockThumbnailUseCase(
                cachedThumbnails: [ThumbnailEntity(url: thumbnailURL, type: .thumbnail)]
            )
        )

        let image = try await sut.image(for: .init(type: .download, nodeHandle: 7))

        #expect(image != nil)
    }

    @Test func downloadWithoutCachedThumbnailFetchesFromServer() async throws {
        let fetchedURL = try writeTempImage()
        let sut = makeSUT(
            thumbnailUseCase: MockThumbnailUseCase(
                cachedThumbnails: [],
                loadThumbnailResult: .success(ThumbnailEntity(url: fetchedURL, type: .thumbnail))
            )
        )

        let image = try await sut.image(for: .init(type: .download, nodeHandle: 7))

        #expect(image != nil)
    }

    @Test func downloadWithoutServerThumbnailResolvesNilDefinitively() async throws {
        // apiENoent maps to ThumbnailErrorEntity: the node has no thumbnail attribute.
        let sut = makeSUT(
            thumbnailUseCase: MockThumbnailUseCase(
                cachedThumbnails: [],
                loadThumbnailResult: .failure(ThumbnailErrorEntity.noThumbnail(.thumbnail))
            )
        )

        let image = try await sut.image(for: .init(type: .download, nodeHandle: 7))

        #expect(image == nil)
    }

    @Test func downloadTransientFetchFailureThrows() async {
        // Default mock stub fails with GenericErrorEntity (e.g. network failure):
        // the loader must propagate it so callers do not memoize the miss.
        let sut = makeSUT(thumbnailUseCase: MockThumbnailUseCase(cachedThumbnails: []))

        await #expect(throws: GenericErrorEntity.self) {
            _ = try await sut.image(for: .init(type: .download, nodeHandle: 7))
        }
    }

    @Test func downloadSecondLoadServesFromMemoryCache() async throws {
        let thumbnailURL = try writeTempImage()
        let sut = makeSUT(
            thumbnailUseCase: MockThumbnailUseCase(
                cachedThumbnails: [ThumbnailEntity(url: thumbnailURL, type: .thumbnail)]
            )
        )
        let first = try await sut.image(for: .init(type: .download, nodeHandle: 7))
        #expect(first != nil)

        // Remove the backing file: only the in-memory cache can produce an image now.
        try FileManager.default.removeItem(at: thumbnailURL)
        let second = try await sut.image(for: .init(type: .download, nodeHandle: 7))

        #expect(second != nil)
    }

    // MARK: - Uploads

    @Test func uploadGeneratesThumbnailFromStagedFile() async throws {
        let generator = MockFileAttributeGenerator(stubbedThumbnail: Self.makeImage())
        let sut = makeSUT(generator: generator)

        let image = try await sut.image(for: .init(type: .upload, path: "/staged/photo.jpg"))

        #expect(image != nil)
        #expect(generator.requestThumbnailCallCount == 1)
    }

    @Test func uploadWithoutSourcePathReturnsNil() async throws {
        let generator = MockFileAttributeGenerator(stubbedThumbnail: Self.makeImage())
        let sut = makeSUT(generator: generator)

        let image = try await sut.image(for: .init(type: .upload, path: nil))

        #expect(image == nil)
        #expect(generator.requestThumbnailCallCount == 0)
    }

    @Test func uploadGenerationFailureReturnsNil() async throws {
        let generator = MockFileAttributeGenerator(stubbedThumbnail: nil)
        let sut = makeSUT(generator: generator)

        let image = try await sut.image(for: .init(type: .upload, path: "/staged/document.pdf"))

        #expect(image == nil)
    }

    @Test func uploadSecondLoadUsesCacheWithoutRegenerating() async throws {
        let generator = MockFileAttributeGenerator(stubbedThumbnail: Self.makeImage())
        let sut = makeSUT(generator: generator)

        _ = try await sut.image(for: .init(type: .upload, path: "/staged/photo.jpg"))
        let second = try await sut.image(for: .init(type: .upload, path: "/staged/photo.jpg"))

        #expect(second != nil)
        #expect(generator.requestThumbnailCallCount == 1)
    }

    @Test func completedUploadServesMigratedThumbnailByNodeHandle() async throws {
        let generator = MockFileAttributeGenerator(stubbedThumbnail: Self.makeImage())
        let sut = makeSUT(generator: generator)
        _ = try await sut.image(for: .init(type: .upload, path: "/staged/photo.jpg"))

        sut.migrateUploadThumbnail(fromPath: "/staged/photo.jpg", toNodeHandle: 7)
        // Post-completion the staged file is gone; only the migrated entry can hit.
        let image = try await sut.image(for: .init(type: .upload, path: "/staged/photo.jpg", nodeHandle: 7))

        #expect(image != nil)
        #expect(generator.requestThumbnailCallCount == 1)
    }

    @Test func migrationWithInvalidHandleEvictsStagedEntry() async throws {
        let generator = MockFileAttributeGenerator(stubbedThumbnail: Self.makeImage())
        let sut = makeSUT(generator: generator)
        _ = try await sut.image(for: .init(type: .upload, path: "/staged/photo.jpg"))

        sut.migrateUploadThumbnail(fromPath: "/staged/photo.jpg", toNodeHandle: .invalid)
        _ = try await sut.image(for: .init(type: .upload, path: "/staged/photo.jpg"))

        #expect(generator.requestThumbnailCallCount == 2)
    }

    @Test func completedUploadFallsBackToCachedNodeThumbnail() async throws {
        // Fresh session: no migrated entry, staged file gone, but the node's
        // thumbnail is in the local cache (e.g. previously viewed in Cloud Drive).
        let thumbnailURL = try writeTempImage()
        let generator = MockFileAttributeGenerator(stubbedThumbnail: nil)
        let sut = makeSUT(
            thumbnailUseCase: MockThumbnailUseCase(
                cachedThumbnails: [ThumbnailEntity(url: thumbnailURL, type: .thumbnail)]
            ),
            generator: generator
        )

        let image = try await sut.image(for: .init(type: .upload, path: "/staged/gone.jpg", nodeHandle: 7))

        #expect(image != nil)
        #expect(generator.requestThumbnailCallCount == 0)
    }

    // MARK: - Other types

    @Test func localHTTPDownloadReturnsNil() async throws {
        let sut = makeSUT()

        let image = try await sut.image(for: .init(type: .localHTTPDownload, nodeHandle: 7))

        #expect(image == nil)
    }

    // MARK: - Helpers

    private func makeSUT(
        thumbnailUseCase: MockThumbnailUseCase = MockThumbnailUseCase(),
        generator: MockFileAttributeGenerator = MockFileAttributeGenerator(stubbedThumbnail: nil)
    ) -> TransferThumbnailLoader {
        TransferThumbnailLoader(
            thumbnailUseCase: thumbnailUseCase,
            makeUploadThumbnailGenerator: { _ in generator }
        )
    }

    private static func makeImage() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
    }

    private func writeTempImage() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString).png")
        let data = try #require(Self.makeImage().pngData())
        try data.write(to: url)
        return url
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
