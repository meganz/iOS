import Foundation
import Combine
import MEGADomain

enum AlbumContentAction: ActionType {
    case onViewReady
}

final class AlbumContentViewModel: NSObject, ViewModelType {
    enum Command: CommandType, Equatable {
        case showAlbum(nodes: [NodeEntity])
        case dismissAlbum
    }
    
    private var albumContentsUseCase: AlbumContentsUseCaseProtocol
    private let cameraUploadNode: NodeEntity?
    private let album: AlbumEntity?
    private let router: AlbumContentRouter
    private var loadingTask: Task<Void, Never>?
    
    private var updateSubscription: AnyCancellable?
    
    let albumName: String
    
    var invokeCommand: ((Command) -> Void)?
    
    // MARK: - Init
    
    init(
        cameraUploadNode: NodeEntity?,
        album: AlbumEntity?,
        albumName: String,
        albumContentsUseCase: AlbumContentsUseCaseProtocol,
        router: AlbumContentRouter
    ) {
        self.cameraUploadNode = cameraUploadNode
        self.album = album
        self.albumContentsUseCase = albumContentsUseCase
        self.router = router
        self.albumName = albumName
        
        super.init()
        
        setupSubscription()
    }
    
    // MARK: - Dispatch action
    
    func dispatch(_ action: AlbumContentAction) {
        switch action {
        case .onViewReady:
            loadingTask = Task {
                await loadNodes()
            }
        }
    }
    
    // MARK: - Internal
    
    func cancelLoading() {
        loadingTask?.cancel()
        loadingTask = nil
    }
    
    // MARK: Private
    @MainActor
    private func loadNodes() async {
        isFavouriteAlbum ? await loadFavouriteNodes() : await loadOtherAlbumNodes()
    }
    
    @MainActor
    private func loadFavouriteNodes() async {
        do {
            let nodes = try await albumContentsUseCase.favouriteAlbumNodes()
            
            invokeCommand?(.showAlbum(nodes: nodes))
        } catch {
            MEGALogError("Error getting favourite nodes")
        }
    }
    
    @MainActor
    private func loadOtherAlbumNodes() async {
        guard let album else { return }
        
        do {
            let nodes = try await albumContentsUseCase.nodes(forAlbum: album)
            nodes.isNotEmpty ? invokeCommand?(.showAlbum(nodes: nodes)) : invokeCommand?(.dismissAlbum)
        } catch {
            MEGALogError("Error getting nodes for album")
        }
    }
    
    private func reloadAlbum() {
        loadingTask = Task {
            try? await Task.sleep(nanoseconds: 0_350_000_000)
            await loadNodes()
        }
    }
    
    private func setupSubscription() {
        updateSubscription = albumContentsUseCase.updatePublisher.sink { [weak self] in
            self?.reloadAlbum()
        }
    }
    
    var isFavouriteAlbum: Bool {
        (cameraUploadNode == nil && album == nil) || (cameraUploadNode != nil && album == nil)
    }
}
