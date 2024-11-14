import MEGAAssets
import MEGADomain
import MEGAPresentation
import SwiftUI

@MainActor
final class PhotoSearchResultItemViewModel: ObservableObject, Identifiable {
    let title: String
    let searchText: String
    @Published private var loadedThumbnailContainer: (any ImageContaining)?
    
    nonisolated var id: HandleEntity {
        photo.handle
    }
    
    var thumbnailContainer: any ImageContaining {
        loadedThumbnailContainer ?? ImageContainer(
            image: MEGAAssetsImageProvider.fileTypeResource(forFileName: photo.name),
            type: .placeholder)
    }
    
    private let photo: NodeEntity
    private let thumbnailLoader: any ThumbnailLoaderProtocol
    private let photoSearchResultRouter: any PhotoSearchResultRouterProtocol
    
    nonisolated init(
        photo: NodeEntity,
        searchText: String,
        thumbnailLoader: some ThumbnailLoaderProtocol,
        photoSearchResultRouter: some PhotoSearchResultRouterProtocol
    ) {
        self.photo = photo
        self.searchText = searchText
        self.thumbnailLoader = thumbnailLoader
        self.photoSearchResultRouter = photoSearchResultRouter
        title = photo.name
    }
    
    func loadThumbnail() async {
        guard let imageContainer = try? await thumbnailLoader.loadImage(for: photo, type: .thumbnail) else {
            return
        }
        loadedThumbnailContainer = imageContainer
    }
    
    func moreButtonPressed(_ button: UIButton) {
        photoSearchResultRouter.didTapMoreAction(on: photo.handle, button: button)
    }
}

extension PhotoSearchResultItemViewModel: Equatable {
    nonisolated static func == (lhs: PhotoSearchResultItemViewModel, rhs: PhotoSearchResultItemViewModel) -> Bool {
        lhs.photo == rhs.photo
    }
}
