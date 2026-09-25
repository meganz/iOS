import Foundation
import MEGADomain
import Testing
@testable import ViewedLinks

@Suite("ViewedLinkThumbnailUseCase")
struct ViewedLinkThumbnailUseCaseTests {
    @Test("a cache hit is returned without hitting the repository's download")
    func cacheHitSkipsDownload() async throws {
        let cached = try makeThumbnail(name: "cached.png")
        let repository = MockViewedLinkThumbnailRepository(cached: cached, downloaded: try makeThumbnail(name: "downloaded.png"))
        let sut = ViewedLinkThumbnailUseCase(repository: repository)

        let thumbnail = try await sut.loadThumbnail(viewedLink: try makeLink())

        #expect(thumbnail.url == cached.url)
        #expect(repository.loadThumbnailCallCount == 0)
    }

    @Test("a cache miss falls through to the download")
    func cacheMissDownloads() async throws {
        let downloaded = try makeThumbnail(name: "downloaded.png")
        let repository = MockViewedLinkThumbnailRepository(downloaded: downloaded)
        let sut = ViewedLinkThumbnailUseCase(repository: repository)
        let link = try makeLink(handle: 9)

        let thumbnail = try await sut.loadThumbnail(viewedLink: link)

        #expect(thumbnail.url == downloaded.url)
        #expect(repository.requestedHandles == [9])
        #expect(repository.loadThumbnailCallCount == 1)
    }

    @Test("a folder link throws without touching the repository")
    func folderLinkThrows() async throws {
        let repository = MockViewedLinkThumbnailRepository(
            cached: try makeThumbnail(name: "cached.png"),
            downloaded: try makeThumbnail(name: "downloaded.png")
        )
        let sut = ViewedLinkThumbnailUseCase(repository: repository)
        let folder = try makeLink(name: "Holiday photos", isFolder: true)

        await #expect(throws: ThumbnailErrorEntity.noThumbnail(.thumbnail)) {
            try await sut.loadThumbnail(viewedLink: folder)
        }
        #expect(repository.cachedThumbnailCallCount == 0)
        #expect(repository.loadThumbnailCallCount == 0)
    }

    @Test("a failed download propagates")
    func failedDownloadPropagates() async throws {
        let repository = MockViewedLinkThumbnailRepository()
        let sut = ViewedLinkThumbnailUseCase(repository: repository)

        await #expect(throws: (any Error).self) {
            try await sut.loadThumbnail(viewedLink: try makeLink())
        }
        #expect(repository.loadThumbnailCallCount == 1)
    }

    // MARK: - Helpers

    private func makeThumbnail(name: String) throws -> ThumbnailEntity {
        let url = try #require(URL(string: "file:///tmp/\(name)"))
        return ThumbnailEntity(url: url, type: .thumbnail)
    }

    private func makeLink(
        handle: HandleEntity = 1,
        name: String = "file.jpg",
        isFolder: Bool = false
    ) throws -> ViewedLinkEntity {
        let url = try #require(URL(string: "https://mega.nz/file/\(handle)#key"))
        return ViewedLinkEntity(
            handle: handle,
            linkURL: url,
            name: name,
            isFolder: isFolder,
            lastAccessed: Date(timeIntervalSince1970: 0)
        )
    }
}
