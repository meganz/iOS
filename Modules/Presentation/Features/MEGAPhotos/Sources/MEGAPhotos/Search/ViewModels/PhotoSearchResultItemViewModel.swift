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
    
    nonisolated init(
        photo: NodeEntity,
        thumbnailLoader: some ThumbnailLoaderProtocol,
        searchText: String
    ) {
        self.photo = photo
        self.thumbnailLoader = thumbnailLoader
        title = photo.name
        self.searchText = searchText
    }
    
    func loadThumbnail() async {
        guard let imageContainer = try? await thumbnailLoader.loadImage(for: photo, type: .thumbnail) else {
            return
        }
        loadedThumbnailContainer = imageContainer
    }
}

extension PhotoSearchResultItemViewModel: Equatable {
    nonisolated static func == (lhs: PhotoSearchResultItemViewModel, rhs: PhotoSearchResultItemViewModel) -> Bool {
        lhs.photo == rhs.photo
    }
}
