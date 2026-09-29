import Foundation
import MEGAAssets
import MEGADomain
import Search
import Testing
import UIKit
@testable import ViewedLinks

@Suite("ViewedLinkSearchResultMapper")
struct ViewedLinkSearchResultMapperTests {
    @Test("a link with a thumbnail renders as a preview")
    func linkWithThumbnailRendersAsPreview() throws {
        let sut = makeSUT()

        let result = sut.map(link: try makeLink(hasThumbnail: true))

        #expect(result.backgroundDisplayMode == .preview)
        #expect(result.hasThumbnail)
    }

    @Test("a link without a thumbnail renders as an icon")
    func linkWithoutThumbnailRendersAsIcon() throws {
        let sut = makeSUT()

        let result = sut.map(link: try makeLink(hasThumbnail: false))

        #expect(result.backgroundDisplayMode == .icon)
        #expect(result.hasThumbnail == false)
    }

    @Test("the result carries the link's own values and no decoration")
    func resultCarriesLinkValues() throws {
        let sut = makeSUT()
        let link = try makeLink(handle: 42, name: "report.pdf", isFolder: true)

        let result = sut.map(link: link)

        #expect(result.id == 42)
        #expect(result.title == "report.pdf")
        #expect(result.isFolder)
        #expect(result.type == .node)
        #expect(result.note == nil)
        #expect(result.tags.isEmpty)
        #expect(result.properties.isEmpty)
        #expect(result.isSensitive == false)
        #expect(result.description(.list).isEmpty)
        #expect(result.swipeActions(.unknown).isEmpty)
    }

    @Test("a link with no thumbnail returns its file-type icon without asking the use case")
    func linkWithNoThumbnailSkipsTheUseCase() async throws {
        let useCase = MockViewedLinkThumbnailUseCase()
        let sut = makeSUT(thumbnailUseCase: useCase)
        let result = sut.map(link: try makeLink(name: "holiday.pdf", hasThumbnail: false))

        let data = await result.thumbnailImageData()

        #expect(data == MEGAAssets.UIImage.image(forFileExtension: "pdf").pngData())
        #expect(useCase.loadThumbnailCallCount == 0)
    }

    @Test("a loaded thumbnail returns the file's own bytes")
    func loadedThumbnailReturnsFileBytes() async throws {
        let thumbnailURL = try writeTemporaryImage()
        defer { try? FileManager.default.removeItem(at: thumbnailURL) }
        let sut = makeSUT(
            thumbnailUseCase: MockViewedLinkThumbnailUseCase(
                thumbnail: ThumbnailEntity(url: thumbnailURL, type: .thumbnail)
            )
        )
        let result = sut.map(link: try makeLink(name: "photo.jpg", hasThumbnail: true))

        let data = await result.thumbnailImageData()

        #expect(data == (try Data(contentsOf: thumbnailURL)))
    }

    @Test("a failed thumbnail load falls back to the file-type icon")
    func failedThumbnailFallsBackToFileTypeIcon() async throws {
        let useCase = MockViewedLinkThumbnailUseCase()
        let sut = makeSUT(thumbnailUseCase: useCase)
        let result = sut.map(link: try makeLink(name: "photo.jpg", hasThumbnail: true))

        let data = await result.thumbnailImageData()

        #expect(data == MEGAAssets.UIImage.image(forFileExtension: "jpg").pngData())
        #expect(useCase.loadThumbnailCallCount == 1)
    }

    @Test("a failed thumbnail load on a folder falls back to the folder icon")
    func failedThumbnailFallsBackToFolderIcon() async throws {
        let sut = makeSUT()
        let folder = try makeLink(name: "Holiday photos", isFolder: true, hasThumbnail: true)
        let result = sut.map(link: folder)

        let data = await result.thumbnailImageData()

        #expect(data == MEGAAssets.UIImage.filetypeFolder.pngData())
    }

    // MARK: - Helpers

    private func makeSUT(
        thumbnailUseCase: MockViewedLinkThumbnailUseCase = MockViewedLinkThumbnailUseCase()
    ) -> ViewedLinkSearchResultMapper {
        ViewedLinkSearchResultMapper(thumbnailUseCase: thumbnailUseCase)
    }

    /// The mock's thumbnail URL has to point at a real file or a success would be indistinguishable
    /// from the icon fallback.
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
        isFolder: Bool = false,
        hasThumbnail: Bool = false
    ) throws -> ViewedLinkEntity {
        let url = try #require(URL(string: "https://mega.nz/file/\(handle)#key"))
        return ViewedLinkEntity(
            handle: handle,
            linkURL: url,
            name: name,
            isFolder: isFolder,
            hasThumbnail: hasThumbnail,
            lastAccessed: Date(timeIntervalSince1970: 0)
        )
    }
}
