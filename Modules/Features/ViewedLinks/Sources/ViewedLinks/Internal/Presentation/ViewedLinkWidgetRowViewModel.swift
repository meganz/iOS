import Foundation
import MEGAAppPresentation
import MEGAAssets
import MEGADomain
import MEGASwift
import SwiftUI

@MainActor
final class ViewedLinkWidgetRowViewModel: ObservableObject {
    @Published private(set) var imageContainer: any ImageContaining
    @Published private(set) var name: String

    private(set) var linkURL: URL

    private var link: ViewedLinkWidgetRowModel
    private let thumbnailUseCase: any ViewedLinkThumbnailUseCaseProtocol

    var hasThumbnail: Bool { imageContainer.type != .placeholder }

    package init(
        link: ViewedLinkWidgetRowModel,
        thumbnailUseCase: some ViewedLinkThumbnailUseCaseProtocol
    ) {
        self.link = link
        self.thumbnailUseCase = thumbnailUseCase
        name = link.name
        linkURL = link.linkURL
        // Initially, we set the initial icon in accordance with the link type (file/folder)
        // Then `loadThumbnail()` will update `image` the correct thumbnail
        imageContainer = Self.initialImage(for: link)
    }

    convenience init(link: ViewedLinkWidgetRowModel) {
        self.init(
            link: link,
            thumbnailUseCase: ViewedLinksFactory.makeViewedLinkThumbnailUseCase()
        )
    }

    func loadThumbnail() async {
        guard !link.isFolder, !hasThumbnail, !Task.isCancelled else { return }
        guard
            let thumbnail = try? await thumbnailUseCase.loadThumbnail(viewedLink: link.link),
            let container = await imageContainer(for: thumbnail),
            !Task.isCancelled
        else { return }
        imageContainer = container
    }

    /// Builds the container off the main actor: `URLImageContainer` reads and decodes the file synchronously.
    private nonisolated func imageContainer(for thumbnail: ThumbnailEntity) async -> URLImageContainer? {
        thumbnail.toURLImageContainer()
    }
    
    private static func initialImage(for link: ViewedLinkWidgetRowModel) -> some ImageContaining {
        let image = link.isFolder
        ? MEGAAssets.Image.filetypeFolder
            : MEGAAssets.Image.image(forFileExtension: link.name.pathExtension)
        return ImageContainer(image: image, type: .placeholder)

    }
}
