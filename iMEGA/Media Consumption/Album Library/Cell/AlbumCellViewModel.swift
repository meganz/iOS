import Combine
import SwiftUI

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
            do {
                var nodes = try await albumContentsUseCase.favouriteAlbumNodes()
                nodes = sortMediaNodesInDescending(with: nodes)
                
                let albumEntity = PhotoAlbum(handle: nil, coverNode: nodes.first, numberOfNodes: nodes.count)
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
    
    private func sortMediaNodesInDescending(with nodes: [NodeEntity]) -> [NodeEntity] {
        var nodes = nodes
        
        nodes = nodes.filter({
            return $0.isImage || ($0.isVideo && $0.parentHandle == cameraUploadNode?.handle)
        })
        
        nodes = nodes.sorted { $0.modificationTime >= $1.modificationTime }
        
        return nodes
    }
}
