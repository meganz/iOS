import Foundation
import Combine
import MEGADomain
import MEGAPresentation

enum AlbumContentAction: ActionType {
    case onViewReady
    case changeSortOrder(SortOrderType)
    case changeFilter(FilterType)
}

final class AlbumContentViewModel: ViewModelType {
    enum Command: CommandType, Equatable {
        case showAlbumPhotos(photos: [NodeEntity], sortOrder: SortOrderType)
        case dismissAlbum
        case showHud(String)
    }
    
    private let album: AlbumEntity
    private let albumContentsUseCase: AlbumContentsUseCaseProtocol
    private let mediaUseCase: MediaUseCaseProtocol
    private let albumContentModificationUseCase: AlbumContentModificationUseCaseProtocol
    private let photoLibraryUseCase: PhotoLibraryUseCaseProtocol
    private let router: AlbumContentRouting
    private var loadingTask: Task<Void, Never>?
    private var photos = [NodeEntity]()
    private var updateSubscription: AnyCancellable?
    private var selectedSortOrder: SortOrderType = .newest
    private var selectedFilter: FilterType = .allMedia
    private var addAdditionalPhotosTask: Task<Void, Never>?
    private var newAlbumPhotosToAdd: [NodeEntity]?
    private var doesPhotoLibraryContainPhotos: Bool = false
    
    let albumName: String
    var invokeCommand: ((Command) -> Void)?
    
    // MARK: - Init
    
    init(
        album: AlbumEntity,
        albumContentsUseCase: AlbumContentsUseCaseProtocol,
        mediaUseCase: MediaUseCaseProtocol,
        albumContentModificationUseCase: AlbumContentModificationUseCaseProtocol,
        photoLibraryUseCase: PhotoLibraryUseCaseProtocol,
        router: AlbumContentRouting,
        newAlbumPhotosToAdd: [NodeEntity]? = nil
    ) {
        self.album = album
        self.newAlbumPhotosToAdd = newAlbumPhotosToAdd
        self.albumContentsUseCase = albumContentsUseCase
        self.mediaUseCase = mediaUseCase
        self.albumContentModificationUseCase = albumContentModificationUseCase
        self.photoLibraryUseCase = photoLibraryUseCase
        self.router = router
        self.albumName = album.name
        
        setupSubscription()
    }
    
    // MARK: - Dispatch action
    
    func dispatch(_ action: AlbumContentAction) {
        switch action {
        case .onViewReady:
            loadingTask = Task {
                await addNewAlbumPhotosIfNeeded()
                await loadNodes()
            }
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
    
    var canAddPhotosToAlbum: Bool {
        album.type == .user && !doesPhotoLibraryContainPhotos
    }
    
    var contextMenuConfiguration: CMConfigEntity? {
        guard !(photos.isEmpty && isFavouriteAlbum) else { return nil }
        
        return CMConfigEntity(
            menuType: .menu(type: .display),
            sortType: selectedSortOrder.toSortOrderEntity(),
            filterType: selectedFilter.toFilterEntity(),
            albumType: album.type,
            isFilterEnabled: isFilterEnabled,
            isEmptyState: photos.isEmpty
        )
    }
    
    func cancelLoading() {
        loadingTask?.cancel()
        addAdditionalPhotosTask?.cancel()
    }
    
    func showAlbumContentPicker()  {
        router.showAlbumContentPicker(album: album, completion: { [weak self] _, albumPhotos in
            self?.addAdditionalPhotos(albumPhotos)
        })
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
            doesPhotoLibraryContainPhotos = photos.isEmpty
            if photos.isEmpty && album.type == .user {
                doesPhotoLibraryContainPhotos = (try? await photoLibraryUseCase.allPhotos()
                    .isEmpty) ?? true
            }
            shouldDismissAlbum ? invokeCommand?(.dismissAlbum) : showAlbumPhotos()
        } catch {
            MEGALogError("Error getting nodes for album: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    private func addNewAlbumPhotosIfNeeded() async {
        if let newAlbumPhotosToAdd {
            await addPhotos(newAlbumPhotosToAdd)
            self.newAlbumPhotosToAdd = nil
        }
    }
    
    private func addAdditionalPhotos(_ photos: [NodeEntity]) {
        addAdditionalPhotosTask = Task {
            await addPhotos(photos)
        }
    }
    
    @MainActor
    private func addPhotos(_ photos: [NodeEntity]) async {
        let photosToAdd = photos.filter { !self.photos.contains($0) }
        guard photosToAdd.isNotEmpty else {
            return
        }
        do {
            let result = try await albumContentModificationUseCase.addPhotosToAlbum(by: album.id, nodes: photosToAdd)
            if result.success > 0 {
                let message = self.successMessage(forAlbumName: album.name, withNumberOfItmes: result.success)
                invokeCommand?(.showHud(message))
            }
        } catch {
            MEGALogError("Error occurred when adding photos to an album. \(error.localizedDescription)")
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
        updateSubscription = albumContentsUseCase.albumReloadPublisher.sink { [weak self] in
            self?.reloadAlbum()
        }
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
    
    private func successMessage(forAlbumName name: String, withNumberOfItmes num: UInt) -> String {
        Strings.Localizable.CameraUploads.Albums.addedItemTo(Int(num)).replacingOccurrences(of: "[A]", with: "\(name)")
    }
}
