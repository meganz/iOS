import Foundation
import MEGAAssets
import MEGADomain
import MEGAFoundation
import MEGASwift
import Search

struct LeftOffItemSearchResultMapper: Sendable {
    let thumbnailUseCase: any ThumbnailUseCaseProtocol

    func map(item: ResolvedLeftOffItemEntity) -> SearchResult {
        let node = item.node
        return SearchResult(
            id: node.handle,
            isFolder: false,
            backgroundDisplayMode: node.hasThumbnail ? .preview : .icon,
            title: item.item.name,
            note: nil,
            tags: [],
            isSensitive: item.isSensitive,
            hasThumbnail: node.hasThumbnail,
            description: { _ in "" },
            type: .node,
            properties: properties(for: node),
            thumbnailImageData: { await self.loadThumbnail(for: item) },
            swipeActions: { _ in [] }
        )
    }

    // MARK: - Private methods

    private func properties(for node: NodeEntity) -> [ResultProperty] {
        guard node.mediaType == .video, node.duration > 0 else { return [] }
        return [
            ResultProperty(
                id: "duration",
                content: .text(TimeInterval(node.duration).timeString),
                vibrancyEnabled: false,
                placement: { layout in
                    switch layout {
                    case .thumbnail: .secondary(.leading)
                    case .list: .none
                    }
                }
            )
        ]
    }

    private func loadThumbnail(for item: ResolvedLeftOffItemEntity) async -> Data {
        guard item.node.hasThumbnail else { return iconData(for: item) }

        guard
            let thumbnail = try? await thumbnailUseCase.loadThumbnail(for: item.node, type: .thumbnail),
            let data = try? Data(contentsOf: thumbnail.url)
        else {
            return iconData(for: item)
        }

        return data
    }

    private func iconData(for item: ResolvedLeftOffItemEntity) -> Data {
        MEGAAssets.UIImage.image(forFileExtension: item.item.name.pathExtension).pngData() ?? Data()
    }
}
