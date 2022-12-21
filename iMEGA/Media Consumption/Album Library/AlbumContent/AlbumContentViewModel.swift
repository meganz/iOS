import Foundation
import Combine
import MEGADomain

enum AlbumContentAction: ActionType {
    case onViewReady
}

final class AlbumContentViewModel: ViewModelType {
    enum Command: CommandType, Equatable {
        case showAlbum(nodes: [NodeEntity])
        case dismissAlbum
    }
    
    private var albumContentsUseCase: AlbumContentsUseCaseProtocol
    private let album: AlbumEntity
    private let router: AlbumContentRouter
    private var loadingTask: Task<Void, Never>?
    
    private var updateSubscription: AnyCancellable?
    
    let albumName: String
    
    var invokeCommand: ((Command) -> Void)?
    
    // MARK: - Init
    
    init(
        album: AlbumEntity,
        albumContentsUseCase: AlbumContentsUseCaseProtocol,
        router: AlbumContentRouter
    ) {
        self.album = album
        self.albumContentsUseCase = albumContentsUseCase
        self.router = router
        self.albumName = album.name
        
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
    }
    
    // MARK: Private
    @MainActor
    private func loadNodes() async {
        do {
            var nodes = try await albumContentsUseCase.nodes(forAlbum: album)
            if album.type == .favourite {
                nodes.sort {
                    if $0.modificationTime == $1.modificationTime {
                        return $0.handle > $1.handle
                    }
                    return $0.modificationTime > $1.modificationTime
                }
            }
            nodes.isNotEmpty || album.type == .favourite ? invokeCommand?(.showAlbum(nodes: nodes)) : invokeCommand?(.dismissAlbum)
        } catch {
            MEGALogError("Error getting nodes for album: \(error.localizedDescription)")
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
        album.type == .favourite
    }
}
