import Foundation
import Combine
import MEGADomain
import MEGAPresentation

enum AlbumContentAction: ActionType {
    case onViewReady
    case changeSortOrder(SortOrderType)
    case changeFilter(FilterType)
    case showAlbumCoverPicker
    case deletePhotos([NodeEntity])
}

final class AlbumContentViewModel: ViewModelType {
    enum Command: CommandType, Equatable {
        case showAlbumPhotos(photos: [NodeEntity], sortOrder: SortOrderType)
        case dismissAlbum
        case showHud(MessageType)
        case updateNavigationTitle
        
        enum MessageType: Equatable {
            case success(String)
            case custom(UIImage, String)
        }
    }
    
    private var album: AlbumEntity
    private let albumContentsUseCase: AlbumContentsUseCaseProtocol
    private let albumContentModificationUseCase: AlbumContentModificationUseCaseProtocol
    private let photoLibraryUseCase: PhotoLibraryUseCaseProtocol
    private let router: AlbumContentRouting
    private var loadingTask: Task<Void, Never>?
    private var photos = [AlbumPhotoEntity]()
    private var subscriptions = Set<AnyCancellable>()
    private var selectedSortOrder: SortOrderType = .newest
    private var selectedFilter: FilterType = .allMedia
    private var addAdditionalPhotosTask: Task<Void, Never>?
    private var newAlbumPhotosToAdd: [NodeEntity]?
    private var doesPhotoLibraryContainPhotos: Bool = false
    private var deletePhotosTask: Task<Void, Never>?
    
    private(set) var alertViewModel: TextFieldAlertViewModel
    
    var albumName: String
    var invokeCommand: ((Command) -> Void)?
    
    var renameAlbumTask: Task<Void, Never>?
    var selectAlbumCoverTask: Task<Void, Never>?
    
    // MARK: - Init
    
    init(
        album: AlbumEntity,
        albumContentsUseCase: AlbumContentsUseCaseProtocol,
        albumContentModificationUseCase: AlbumContentModificationUseCaseProtocol,
        photoLibraryUseCase: PhotoLibraryUseCaseProtocol,
        router: AlbumContentRouting,
        newAlbumPhotosToAdd: [NodeEntity]? = nil,
        alertViewModel: TextFieldAlertViewModel
    ) {
        self.album = album
        self.newAlbumPhotosToAdd = newAlbumPhotosToAdd
        self.albumContentsUseCase = albumContentsUseCase
        self.albumContentModificationUseCase = albumContentModificationUseCase
        self.photoLibraryUseCase = photoLibraryUseCase
        self.router = router
        self.albumName = album.name
        self.alertViewModel = alertViewModel
        
        setupSubscription()
        setupAlbumModification()
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
        case .showAlbumCoverPicker:
            showAlbumCoverPicker()
        case .deletePhotos(let photos):
            deletePhotosTask = Task {
                await deletePhotos(photos)
            }
        }
    }
    
    // MARK: - Internal
    var isFavouriteAlbum: Bool {
        album.type == .favourite
    }
    
    var albumType: AlbumType {
        switch album.type {
        case .favourite:
            return .favourite
        case .raw:
            return .raw
        case .gif:
            return .gif
        case .user:
            return .user
        }
    }
    
    var canAddPhotosToAlbum: Bool {
        album.type == .user && !doesPhotoLibraryContainPhotos
    }
    
    var contextMenuConfiguration: CMConfigEntity? {
        guard !(photos.isEmpty && isFavouriteAlbum) else { return nil }
        
        return CMConfigEntity(
            menuType: .menu(type: .album),
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
    
    func renameAlbum(with name: String) {
        renameAlbumTask = Task { [weak self] in
            do {
                let newName = try await albumContentModificationUseCase.rename(album: album.id, with: name)
                await self?.onAlbumRenameSuccess(with: newName)
            } catch {
                MEGALogError("Error renaming user album: \(error.localizedDescription)")
            }
        }
    }
    
    func updateAlertViewModel() {
        alertViewModel.textString = albumName
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
            return photos.contains(where: { $0.photo.mediaType == .video })
        case .videos:
            return photos.contains(where: { $0.photo.mediaType == .image })
        default:
            return containsImageAndVideoPhotos
        }
    }
    
    private var containsImageAndVideoPhotos: Bool {
        let containsImage = photos.contains(where: { $0.photo.mediaType == .image })
        let containsVideo = photos.contains(where: { $0.photo.mediaType == .video })
        return containsImage && containsVideo
    }
    
    private var filteredPhotos: [AlbumPhotoEntity] {
        switch selectedFilter {
        case .images:
            return photos.filter { $0.photo.mediaType == .image }
        case .videos:
            return photos.filter { $0.photo.mediaType == .video }
        default:
            return photos
        }
    }
    
    @MainActor
    private func loadNodes() async {
        do {
            photos = try await albumContentsUseCase.photos(in: album)
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
        let photosToAdd = photos.filter { photo in !self.photos.contains(where: { photo == $0.photo }) }
        guard photosToAdd.isNotEmpty else {
            return
        }
        do {
            let result = try await albumContentModificationUseCase.addPhotosToAlbum(by: album.id, nodes: photosToAdd)
            if result.success > 0 {
                let message = self.successMessage(forAlbumName: album.name, withNumberOfItmes: result.success)
                invokeCommand?(.showHud(.success(message)))
            }
        } catch {
            MEGALogError("Error occurred when adding photos to an album. \(error.localizedDescription)")
        }
    }
    
    private func showAlbumPhotos() {
        if selectedFilter != .allMedia && !containsImageAndVideoPhotos {
            selectedFilter = .allMedia
        }
        invokeCommand?(.showAlbumPhotos(photos: filteredPhotos.map { $0.photo }, sortOrder: selectedSortOrder))
    }
        
    private var shouldDismissAlbum: Bool {
        photos.isEmpty && (album.type == .raw || album.type == .gif)
    }
    
    private func reloadAlbum() {
        loadingTask = Task {
            await loadNodes()
        }
    }
    
    private func setupSubscription() {
        albumContentsUseCase.albumReloadPublisher(forAlbum: album)
            .debounce(for: .seconds(0.35), scheduler: DispatchQueue.global())
            .sink { [weak self] in
                self?.reloadAlbum()
            }.store(in: &subscriptions)
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
    
    private func setupAlbumModification() {
        alertViewModel.action = { [weak self] newName in
            guard let newName = newName else { return }
            self?.renameAlbum(with: newName)
        }
    }
    
    @MainActor
    private func onAlbumRenameSuccess(with newName: String) {
        albumName = newName
        invokeCommand?(.updateNavigationTitle)
    }
    
    private func updateAlbumCover(albumPhoto: AlbumPhotoEntity) {
        selectAlbumCoverTask = Task { [weak self] in
            do {
                let _ = try await albumContentModificationUseCase.updateAlbumCover(album: album.id, withAlbumPhoto: albumPhoto)
                album.coverNode = albumPhoto.photo
                
                let message = Strings.Localizable.CameraUploads.Albums.albumCoverUpdated
                self?.invokeCommand?(.showHud(.success(message)))
            } catch {
                MEGALogError("Error updating user album cover: \(error.localizedDescription)")
            }
        }
    }
    
    private func showAlbumCoverPicker()  {
        router.showAlbumCoverPicker(album: album, completion: { [weak self] _, coverPhoto in
            self?.updateAlbumCover(albumPhoto: coverPhoto)
        })
    }

    @MainActor
    private func deletePhotos(_ photos: [NodeEntity]) async {
        let photosToDelete = self.photos.filter { albumPhoto in photos.contains(where: { albumPhoto.id == $0.handle }) }
        guard photosToDelete.isNotEmpty else {
            return
        }
        do {
            let result = try await albumContentModificationUseCase.deletePhotos(in: album.id, photos: photosToDelete)
            if result.success > 0 {
                let message = Strings.Localizable.CameraUploads.Albums.removedItemFrom(Int(result.success))
                    .replacingOccurrences(of: "[A]", with: "\(albumName)")
                invokeCommand?(.showHud(.custom(Asset.Images.Hud.hudMinus.image, message)))
            }
        } catch {
            MEGALogError("Error occurred when deleting photos for the album. \(error.localizedDescription)")
        }
    }
}
