import Foundation
import MEGAAssets
import MEGADomain
import SwiftUI
import Testing
import UIKit
@testable import ViewedLinks

@Suite("ViewedLinkWidgetRowViewModel")
@MainActor
struct ViewedLinkWidgetRowViewModelTests {
    @Test("a file row starts on its file-type icon")
    func fileRowStartsOnFileTypeIcon() throws {
        let link = try makeLink(name: "holiday.pdf")

        let sut = makeSUT(link: link)

        #expect(sut.imageContainer.image == MEGAAssets.Image.image(forFileExtension: "pdf"))
        #expect(sut.hasThumbnail == false)
    }

    @Test("a folder row starts on the folder icon")
    func folderRowStartsOnFolderIcon() throws {
        let link = try makeLink(name: "Holiday photos", isFolder: true)

        let sut = makeSUT(link: link)

        #expect(sut.imageContainer.image == MEGAAssets.Image.filetypeFolder)
        #expect(sut.hasThumbnail == false)
    }

    @Test("the row exposes the link's name and URL")
    func rowExposesLinkValues() throws {
        let link = try makeLink(handle: 7, name: "report.jpg")

        let sut = makeSUT(link: link)

        #expect(sut.name == "report.jpg")
        #expect(sut.linkURL == link.linkURL)
    }

    @Test("loadThumbnail replaces the icon when the thumbnail is cached")
    func loadThumbnailUsesCachedFile() async throws {
        let cachedURL = try writeTemporaryImage()
        defer { try? FileManager.default.removeItem(at: cachedURL) }
        let link = try makeLink(name: "photo.jpg")
        let sut = makeSUT(
            link: link,
            thumbnailUseCase: MockViewedLinkThumbnailUseCase(
                thumbnail: ThumbnailEntity(url: cachedURL, type: .thumbnail)
            )
        )

        await sut.loadThumbnail()

        #expect(sut.hasThumbnail)
        #expect(sut.imageContainer.image != MEGAAssets.Image.image(forFileExtension: "jpg"))
    }

    @Test("loadThumbnail keeps the file-type icon when nothing resolves")
    func loadThumbnailKeepsIconOnFailure() async throws {
        let link = try makeLink(name: "photo.jpg")
        let sut = makeSUT(link: link)

        await sut.loadThumbnail()

        #expect(sut.hasThumbnail == false)
        #expect(sut.imageContainer.image == MEGAAssets.Image.image(forFileExtension: "jpg"))
    }

    @Test("loadThumbnail leaves a folder row on the folder icon")
    func loadThumbnailSkipsFolders() async throws {
        let cachedURL = try writeTemporaryImage()
        defer { try? FileManager.default.removeItem(at: cachedURL) }
        let link = try makeLink(name: "Holiday photos", isFolder: true)
        let useCase = MockViewedLinkThumbnailUseCase(
            thumbnail: ThumbnailEntity(url: cachedURL, type: .thumbnail)
        )
        let sut = makeSUT(link: link, thumbnailUseCase: useCase)

        await sut.loadThumbnail()

        #expect(sut.hasThumbnail == false)
        #expect(sut.imageContainer.image == MEGAAssets.Image.filetypeFolder)
        #expect(useCase.loadThumbnailCallCount == 0)
    }

    @Test("loadThumbnail is not repeated once a thumbnail is on screen")
    func loadThumbnailRunsOnceOnSuccess() async throws {
        let cachedURL = try writeTemporaryImage()
        defer { try? FileManager.default.removeItem(at: cachedURL) }
        let useCase = MockViewedLinkThumbnailUseCase(
            thumbnail: ThumbnailEntity(url: cachedURL, type: .thumbnail)
        )
        let sut = makeSUT(link: try makeLink(name: "photo.jpg"), thumbnailUseCase: useCase)

        await sut.loadThumbnail()
        await sut.loadThumbnail()

        #expect(sut.hasThumbnail)
        #expect(useCase.loadThumbnailCallCount == 1)
    }

    @Test("loadThumbnail retries after a failure and recovers")
    func loadThumbnailRetriesAfterFailure() async throws {
        let cachedURL = try writeTemporaryImage()
        defer { try? FileManager.default.removeItem(at: cachedURL) }
        let useCase = MockViewedLinkThumbnailUseCase(
            results: [nil, ThumbnailEntity(url: cachedURL, type: .thumbnail)]
        )
        let sut = makeSUT(link: try makeLink(name: "photo.jpg"), thumbnailUseCase: useCase)

        await sut.loadThumbnail()
        #expect(sut.hasThumbnail == false)

        await sut.loadThumbnail()

        #expect(sut.hasThumbnail)
        #expect(useCase.loadThumbnailCallCount == 2)
    }

    // MARK: - Helpers

    private func makeSUT(
        link: ViewedLinkEntity,
        thumbnailUseCase: MockViewedLinkThumbnailUseCase = MockViewedLinkThumbnailUseCase()
    ) -> ViewedLinkWidgetRowViewModel {
        ViewedLinkWidgetRowViewModel(
            link: link.toWidgetRowModel,
            thumbnailUseCase: thumbnailUseCase
        )
    }

    /// The mock's default cache URL is not a real file, so a cache hit has to be backed by one
    /// on disk or the test would pass for the wrong reason.
    private func writeTemporaryImage() throws -> URL {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4)).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        }
        let data = try #require(image.pngData())
        let url = URL.temporaryDirectory.appending(path: "\(UUID().uuidString).png")
        try data.write(to: url)
        return url
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
            hasThumbnail: false,
            lastAccessed: Date(timeIntervalSince1970: 0)
        )
    }
}
