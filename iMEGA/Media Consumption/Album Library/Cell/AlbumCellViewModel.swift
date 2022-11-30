import Combine
import SwiftUI
import MEGASwiftUI
import MEGADomain

final class AlbumCellViewModel: NSObject, ObservableObject {
    let album: AlbumEntity?
    @Published var numberOfNodes = 0
    @Published var thumbnailContainer: any ImageContaining
    @Published var isLoading: Bool
    
    @Published var title: String = ""
    
    private var cameraUploadNode: NodeEntity?
    private var thumbnailUseCase: ThumbnailUseCaseProtocol
    private var albumContentsUseCase: AlbumContentsUseCaseProtocol
    private let placeholderThumbnail: ImageContainer
    private var loadingTask: Task<Void, Never>?
    
    private var updateSubscription: AnyCancellable?
    
    var isFavouriteAlbum: Bool {
        self.album == nil
    }
    
    init(
        cameraUploadNode: NodeEntity?,
        thumbnailUseCase: ThumbnailUseCaseProtocol,
        albumContentsUseCase: AlbumContentsUseCaseProtocol,
        album: AlbumEntity?
    ) {
        self.cameraUploadNode = cameraUploadNode
        self.thumbnailUseCase = thumbnailUseCase
        self.albumContentsUseCase = albumContentsUseCase
        self.album = album
        
        if let album = self.album {
            title = album.name
            numberOfNodes = album.count
        } else {
            title = Strings.Localizable.CameraUploads.Albums.Favourites.title
        }
        
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
            if isFavouriteAlbum {
                await loadFavouriteAlbum()
            } else {
                await loadOtherAlbumThumbnail()
            }
        }
    }
    
    func cancelLoading() {
        isLoading = false
        loadingTask?.cancel()
        loadingTask = nil
    }
    
    // MARK: Private
    
    @MainActor
    private func loadFavouriteAlbum() async {
        guard let nodes = try? await albumContentsUseCase.favouriteAlbumNodes() else {
            isLoading = false
            return
        }
        
        let albumEntity = PhotoAlbum(handle: nil, coverNode: nodes.first, numberOfNodes: nodes.count)
        numberOfNodes = albumEntity.numberOfNodes
        
        if let node = albumEntity.coverNode {
            await loadThumbnail(for: node)
        } else {
            isLoading = false
            thumbnailContainer = placeholderThumbnail
        }
    }
    
    @MainActor
    private func loadOtherAlbumThumbnail() async {
        if let node = album?.coverNode {
            await loadThumbnail(for: node)
        } else {
            isLoading = false
            thumbnailContainer = placeholderThumbnail
        }
    }
    
    @MainActor
    private func loadThumbnail(for node: NodeEntity) async {
        guard let imageContainer = try? await thumbnailUseCase.loadThumbnailImageContainer(for: node, type: .thumbnail) else {
            isLoading = false
            return
        }
        
        thumbnailContainer = imageContainer
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
