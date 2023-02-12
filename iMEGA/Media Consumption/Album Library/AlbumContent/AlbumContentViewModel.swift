import Foundation
import Combine
import MEGADomain

enum AlbumContentAction: ActionType {
    case onViewReady
    case onViewDidAppear
    case changeSortOrder(SortOrderType)
}

final class AlbumContentViewModel: ViewModelType {
    enum Command: CommandType, Equatable {
        case showAlbumPhotos(photos: [NodeEntity], sortOrder: SortOrderType)
        case dismissAlbum
        case showHud(String)
    }
    
    private var albumContentsUseCase: AlbumContentsUseCaseProtocol
    private let album: AlbumEntity
    private let router: AlbumContentRouter
    private var loadingTask: Task<Void, Never>?
    private var photos = [NodeEntity]()
    private var updateSubscription: AnyCancellable?
    private var selectedSortOrder: SortOrderType = .newest
    
    let albumName: String
    var messageForNewAlbum: String?
    
    var invokeCommand: ((Command) -> Void)?
    
    // MARK: - Init
    
    init(
        album: AlbumEntity,
        messageForNewAlbum: String? = nil,
        albumContentsUseCase: AlbumContentsUseCaseProtocol,
        router: AlbumContentRouter
    ) {
        self.album = album
        self.messageForNewAlbum = messageForNewAlbum
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
        case .onViewDidAppear:
            showNewlyAddedAlbumHud()
        case .changeSortOrder(let sortOrder):
            updateSortOrder(sortOrder)
        }
    }
    
    // MARK: - Internal
    var isFavouriteAlbum: Bool {
        album.type == .favourite
    }
    
    var contextMenuConfiguration: CMConfigEntity {
        return CMConfigEntity(
            menuType: .menu(type: .display),
            sortType: selectedSortOrder.toSortOrderEntity(),
            filterType: .allMedia,
            isAlbum: true,
            isFilterEnabled: isFilterEnabled,
            isEmptyState: photos.isEmpty
        )
    }
    
    func cancelLoading() {
        loadingTask?.cancel()
    }
    
    // MARK: Private
    @MainActor
    private func loadNodes() async {
        do {
            photos = try await albumContentsUseCase.nodes(forAlbum: album)
            shouldDismissAlbum ? invokeCommand?(.dismissAlbum) : invokeCommand?(.showAlbumPhotos(photos: photos, sortOrder: selectedSortOrder))
        } catch {
            MEGALogError("Error getting nodes for album: \(error.localizedDescription)")
        }
    }
    
    private var shouldDismissAlbum: Bool {
        photos.isEmpty && (album.type == .raw || album.type == .gif)
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
    
    private func showNewlyAddedAlbumHud() {
        guard let message = messageForNewAlbum else { return }
        invokeCommand?(.showHud(message))
        messageForNewAlbum = nil
    }
    
    private func updateSortOrder(_ sortOrder: SortOrderType) {
        guard sortOrder != selectedSortOrder else { return }
        selectedSortOrder = sortOrder
        invokeCommand?(.showAlbumPhotos(photos: photos, sortOrder: selectedSortOrder))
    }
    
    private var isFilterEnabled: Bool {
        guard photos.isNotEmpty else {
            return false
        }
        return album.type == .user || isFavouriteAlbum
    }
}
