import Combine
import SwiftUI

@available(iOS 14.0, *)
final class AlbumCellViewModel: NSObject, ObservableObject {
    @Published var numberOfNodes = 0
    @Published var thumbnailContainer: ImageContainer
    @Published var isLoading: Bool
    
    var title = Strings.Localizable.CameraUploads.Albums.Favourites.title
    
    private var album: NodeEntity
    private var favouriteUseCase: FavouriteNodesUseCaseProtocol
    private var thumbnailUseCase: ThumbnailUseCaseProtocol
    private var albumContentsUseCase: AlbumContentsUpdateNotifierUseCase
    private let placeholderThumbnail: ImageContainer
    private var loadingTask: Task<Void, Never>?
    
    private var updateSubscription: AnyCancellable?
    
    init(
        album: NodeEntity,
        favouriteUseCase: FavouriteNodesUseCaseProtocol,
        thumbnailUseCase: ThumbnailUseCaseProtocol,
        albumContentsUseCase: AlbumContentsUpdateNotifierUseCase
    ) {
        self.album = album
        self.favouriteUseCase = favouriteUseCase
        self.thumbnailUseCase = thumbnailUseCase
        self.albumContentsUseCase = albumContentsUseCase
        
        isLoading = false
        
        placeholderThumbnail = ImageContainer(image: Image(Asset.Images.Album.placeholder.name), isPlaceholder: true)
        thumbnailContainer = placeholderThumbnail
        
        super.init()
        
        setupSubscription()
    }
    
    @MainActor
    func loadAlbumInfo() {
        if !isLoading {
            isLoading.toggle()
        }
        
        loadingTask = Task {
            do {
                let albumEntity = try await favouriteUseCase.favouriteAlbum(withCUHandle: album.handle)
                numberOfNodes = albumEntity.numberOfNodes
                
                if let node = albumEntity.coverNode {
                    await loadThumbnail(for: node)
                } else {
                    isLoading = false
                    thumbnailContainer = placeholderThumbnail
                }
            } catch {}
        }
    }
    
    func cancelLoading() {
        isLoading = false
        loadingTask?.cancel()
        loadingTask = nil
    }
    
    // MARK: Private
    
    @MainActor
    private func loadThumbnail(for node: NodeEntity) async {
        if let image = thumbnailUseCase.cachedThumbnailImage(for: node, type: .thumbnail) {
            thumbnailContainer = ImageContainer(image: image)
        } else {
            do {
                try await loadThumbnailFromRemote(for: node)
            } catch {}
        }
        
        isLoading = false
    }
    
    @MainActor
    private func loadThumbnailFromRemote(for node: NodeEntity) async throws {
        let url = try await thumbnailUseCase.loadThumbnail(for: node, type: .thumbnail)
        
        if let image = Image(contentsOfFile: url.path) {
            thumbnailContainer = ImageContainer(image: image)
        }
        
        isLoading = false
    }
    
    private func reloadAlbumInfo() {
        loadingTask = Task {
            await loadAlbumInfo()
        }
    }

    private func setupSubscription() {
        updateSubscription = albumContentsUseCase.updatePublisher.sink { [weak self] in
            self?.reloadAlbumInfo()
        }
    }
}
