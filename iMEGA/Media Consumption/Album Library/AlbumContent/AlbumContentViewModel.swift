import Foundation

enum AlbumContentAction: ActionType {
    case onViewReady
}

@available(iOS 14.0, *)
final class AlbumContentViewModel: NSObject, ViewModelType {
    enum Command: CommandType, Equatable {
        case showAlbum(nodes: [NodeEntity])
    }
    
    private var favouritesUseCase: FavouriteNodesUseCaseProtocol
    private let cameraUploadNode: NodeEntity
    private let router: AlbumContentRouter
    private var loadingTask: Task<Void, Never>?
    
    let albumName: String
    
    var invokeCommand: ((Command) -> Void)?
    
    // MARK: - Init
    
    init(cameraUploadNode: NodeEntity, albumName: String, favouritesUseCase: FavouriteNodesUseCaseProtocol, router: AlbumContentRouter) {
        self.cameraUploadNode = cameraUploadNode
        self.favouritesUseCase = favouritesUseCase
        self.router = router
        self.albumName = albumName
        
        super.init()
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
        do {
            let nodes = try await favouritesUseCase.favouriteAlbumsMediaNodes(withCUHandle: cameraUploadNode.handle)
            
            invokeCommand?(.showAlbum(nodes: nodes))
        } catch {
            print(error)
        }
    }
}
