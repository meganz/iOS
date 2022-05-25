import Foundation
import Combine

enum AlbumContentAction: ActionType {
    case onViewReady
}

@available(iOS 14.0, *)
final class AlbumContentViewModel: NSObject, ViewModelType {
    enum Command: CommandType, Equatable {
        case showAlbum(nodes: [NodeEntity])
    }
    
    private var favouritesUseCase: FavouriteNodesUseCaseProtocol
    private var albumContentsUseCase: AlbumContentsUpdateNotifierUseCase
    private let cameraUploadNode: NodeEntity?
    private let router: AlbumContentRouter
    private var loadingTask: Task<Void, Never>?
    
    private var updateSubscription: AnyCancellable?
    
    let albumName: String
    
    var invokeCommand: ((Command) -> Void)?
    
    // MARK: - Init
    
    init(
        cameraUploadNode: NodeEntity?,
        albumName: String,
        favouritesUseCase: FavouriteNodesUseCaseProtocol,
        albumContentsUseCase: AlbumContentsUpdateNotifierUseCase,
        router: AlbumContentRouter
    ) {
        self.cameraUploadNode = cameraUploadNode
        self.favouritesUseCase = favouritesUseCase
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
        do {
            let nodes = try await favouritesUseCase.favouriteAlbumMediaNodes(withCUHandle: cameraUploadNode?.handle)

            invokeCommand?(.showAlbum(nodes: nodes))
        } catch {
            print(error)
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
}
