import Combine
import SwiftUI
import MEGASwiftUI
import MEGADomain

@available(iOS 14.0, *)
final class AlbumCellViewModel: NSObject, ObservableObject {
    @Published var numberOfNodes = 0
    @Published var thumbnailContainer: ImageContainer
    @Published var isLoading: Bool
    
    var title = Strings.Localizable.CameraUploads.Albums.Favourites.title
    
    private var cameraUploadNode: NodeEntity?
    private var thumbnailUseCase: ThumbnailUseCaseProtocol
    private var albumContentsUseCase: AlbumContentsUseCaseProtocol
    private let placeholderThumbnail: ImageContainer
    private var loadingTask: Task<Void, Never>?
    
    private var updateSubscription: AnyCancellable?
    
    init(
        cameraUploadNode: NodeEntity?,
        thumbnailUseCase: ThumbnailUseCaseProtocol,
        albumContentsUseCase: AlbumContentsUseCaseProtocol
    ) {
        self.cameraUploadNode = cameraUploadNode
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
    }
    
    func cancelLoading() {
        isLoading = false
        loadingTask?.cancel()
        loadingTask = nil
    }
    
    // MARK: Private
    
    @MainActor
    private func loadThumbnail(for node: NodeEntity) async {
        guard let image = try? await thumbnailUseCase.loadThumbnailImage(for: node, type: .thumbnail) else {
            isLoading = false
            return
        }
        
        thumbnailContainer = ImageContainer(image: image)
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
