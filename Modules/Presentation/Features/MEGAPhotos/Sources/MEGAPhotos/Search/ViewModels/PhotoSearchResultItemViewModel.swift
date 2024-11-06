import MEGAAssets
import MEGADomain
import MEGAPresentation
import SwiftUI

final class PhotoSearchResultItemViewModel: ObservableObject, Identifiable {
    let title: String
    @Published var searchText = ""
    @Published var thumbnailContainer: any ImageContaining
    
    var id: HandleEntity {
        photo.handle
    }
    
    private let photo: NodeEntity
    private let thumbnailLoader: any ThumbnailLoaderProtocol
    
    init(photo: NodeEntity,
         thumbnailLoader: some ThumbnailLoaderProtocol,
         searchTextPublisher: Published<String>.Publisher
    ) {
        self.photo = photo
        self.thumbnailLoader = thumbnailLoader
        title = photo.name
        
        thumbnailContainer = thumbnailLoader.initialImage(for: photo, type: .thumbnail, placeholder: {
            MEGAAssetsImageProvider.fileTypeResource(forFileName: photo.name) })
        
        searchTextPublisher.assign(to: &$searchText)
    }
    
    @MainActor
    func loadThumbnail() async {
        guard thumbnailContainer.type == .placeholder,
              let imageContainer = try? await thumbnailLoader.loadImage(for: photo, type: .thumbnail) else {
            return
        }
        thumbnailContainer = imageContainer
    }
}

extension PhotoSearchResultItemViewModel: Equatable {
    static func == (lhs: PhotoSearchResultItemViewModel, rhs: PhotoSearchResultItemViewModel) -> Bool {
        lhs.photo == rhs.photo
    }
}
