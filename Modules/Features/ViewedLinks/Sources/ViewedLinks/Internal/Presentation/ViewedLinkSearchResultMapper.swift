import Foundation
import MEGAAssets
import MEGADomain
import MEGASwift
import Search

/// Turns a viewed link into a row the Search module can render.
struct ViewedLinkSearchResultMapper: Sendable {
    private let thumbnailUseCase: any ViewedLinkThumbnailUseCaseProtocol

    init(thumbnailUseCase: some ViewedLinkThumbnailUseCaseProtocol) {
        self.thumbnailUseCase = thumbnailUseCase
    }

    func map(link: ViewedLinkEntity) -> SearchResult {
        SearchResult(
            id: link.handle,
            isFolder: link.isFolder,
            backgroundDisplayMode: link.hasThumbnail ? .preview : .icon,
            title: link.name,
            note: nil,
            tags: [],
            isSensitive: false,
            hasThumbnail: link.hasThumbnail,
            description: { _ in "" },
            type: .node,
            properties: [],
            thumbnailImageData: { await self.loadThumbnail(for: link) },
            swipeActions: { _ in [] }
        )
    }

    // MARK: - Private methods

    private func loadThumbnail(for link: ViewedLinkEntity) async -> Data {
        guard link.hasThumbnail else { return iconData(for: link) }

        guard
            let thumbnail = try? await thumbnailUseCase.loadThumbnail(viewedLink: link),
            let data = try? Data(contentsOf: thumbnail.url)
        else {
            return iconData(for: link)
        }

        return data
    }

    private func iconData(for link: ViewedLinkEntity) -> Data {
        let icon = link.isFolder
            ? MEGAAssets.UIImage.filetypeFolder
            : MEGAAssets.UIImage.image(forFileExtension: link.name.pathExtension)

        return icon.pngData() ?? Data()
    }
}
