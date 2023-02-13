import Foundation
import Combine
import MEGADomain

enum AlbumContentAction: ActionType {
    case onViewReady
    case onViewDidAppear
    case changeSortOrder(SortOrderType)
    case changeFilter(FilterType)
}

final class AlbumContentViewModel: ViewModelType {
    enum Command: CommandType, Equatable {
        case showAlbumPhotos(photos: [NodeEntity], sortOrder: SortOrderType)
        case dismissAlbum
        case showHud(String)
    }
    
    private let albumContentsUseCase: AlbumContentsUseCaseProtocol
    private let mediaUseCase: MediaUseCaseProtocol
    private let album: AlbumEntity
    private let router: AlbumContentRouter
    private var loadingTask: Task<Void, Never>?
    private var photos = [NodeEntity]()
    private var updateSubscription: AnyCancellable?
    private var selectedSortOrder: SortOrderType = .newest
    private var selectedFilter: FilterType = .allMedia
    
    let albumName: String
    var messageForNewAlbum: String?
    
    var invokeCommand: ((Command) -> Void)?
    
    // MARK: - Init
    
    init(
        album: AlbumEntity,
        messageForNewAlbum: String? = nil,
        albumContentsUseCase: AlbumContentsUseCaseProtocol,
        mediaUseCase: MediaUseCaseProtocol,
        router: AlbumContentRouter
    ) {
        self.album = album
        self.messageForNewAlbum = messageForNewAlbum
        self.albumContentsUseCase = albumContentsUseCase
        self.mediaUseCase = mediaUseCase
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
        case .changeFilter(let filter):
            updateFilter(filter)
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
            filterType: selectedFilter.toFilterEntity(),
            isAlbum: true,
            isFilterEnabled: isFilterEnabled,
            isEmptyState: photos.isEmpty
        )
    }
    
    func cancelLoading() {
        loadingTask?.cancel()
    }
    
    // MARK: Private
    private var isFilterEnabled: Bool {
        guard photos.isNotEmpty,
              album.type != .gif,
              album.type != .raw else {
            return false
        }
        switch selectedFilter {
        case .images:
            return photos.contains(where: { mediaUseCase.isVideo($0.name) })
        case .videos:
            return photos.contains(where: { mediaUseCase.isImage($0.name) })
        default:
            let containsImage = photos.contains(where: { mediaUseCase.isImage($0.name) })
            let containsVideo = photos.contains(where: { mediaUseCase.isVideo($0.name) })
            return containsImage && containsVideo
        }
    }
    
    private var filteredPhotos: [NodeEntity] {
        switch selectedFilter {
        case .images:
            return photos.filter { mediaUseCase.isImage($0.name) }
        case .videos:
            return photos.filter { mediaUseCase.isVideo($0.name) }
        default:
            return photos
        }
    }
    
    @MainActor
    private func loadNodes() async {
        do {
            photos = try await albumContentsUseCase.nodes(forAlbum: album)
            shouldDismissAlbum ? invokeCommand?(.dismissAlbum) : showAlbumPhotos()
        } catch {
            MEGALogError("Error getting nodes for album: \(error.localizedDescription)")
        }
    }
    
    private func showAlbumPhotos() {
        invokeCommand?(.showAlbumPhotos(photos: filteredPhotos, sortOrder: selectedSortOrder))
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
        showAlbumPhotos()
    }
    
    private func updateFilter(_ filter: FilterType) {
        guard filter != selectedFilter else { return }
        selectedFilter = filter
        showAlbumPhotos()
    }
}
