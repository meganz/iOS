import Combine
import Foundation
import MEGAAnalyticsiOS
import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGASwiftUI

enum AlbumContentAction: ActionType {
    case onViewReady
    case changeSortOrder(SortOrderType)
    case changeFilter(FilterType)
    case showAlbumCoverPicker
    case deletePhotos([NodeEntity])
    case deleteAlbum
    case configureContextMenu(isSelectHidden: Bool)
    case shareLink
    case removeLink
    case hideNodes
}

final class AlbumContentViewModel: ViewModelType {
    enum Command: CommandType, Equatable {
        case startLoading
        case finishLoading
        case showAlbumPhotos(photos: [NodeEntity], sortOrder: SortOrderType)
        case dismissAlbum
        case showResultMessage(MessageType)
        case updateNavigationTitle
        case showDeleteAlbumAlert
        case rebuildContextMenu
        
        enum MessageType: Equatable {
            case success(String)
            case custom(UIImage, String)
        }
    }
    
    private var album: AlbumEntity
    private let albumContentsUseCase: any AlbumContentsUseCaseProtocol
    private let albumModificationUseCase: any AlbumModificationUseCaseProtocol
    private let photoLibraryUseCase: any PhotoLibraryUseCaseProtocol
    private let router: any AlbumContentRouting
    private let shareCollectionUseCase: any ShareCollectionUseCaseProtocol
    private let tracker: any AnalyticsTracking
    
    private var loadingTask: Task<Void, Never>?
    private var photos = [AlbumPhotoEntity]()
    private var subscriptions = Set<AnyCancellable>()
    private var selectedSortOrder: SortOrderType = .newest
    private var selectedFilter: FilterType = .allMedia
    private var addAdditionalPhotosTask: Task<Void, Never>?
    private var newAlbumPhotosToAdd: [NodeEntity]?
    private var doesPhotoLibraryContainPhotos: Bool = false
    private var deletePhotosTask: Task<Void, Never>?
    private var deleteAlbumTask: Task<Void, Never>?
    
    private(set) var alertViewModel: TextFieldAlertViewModel
    
    var invokeCommand: ((Command) -> Void)?
    var isPhotoSelectionHidden = false
    
    var selectAlbumCoverTask: Task<Void, Never>?
    
    var albumName: String {
        album.name
    }
    
    // MARK: - Init
    
    init(
        album: AlbumEntity,
        albumContentsUseCase: any AlbumContentsUseCaseProtocol,
        albumModificationUseCase: any AlbumModificationUseCaseProtocol,
        photoLibraryUseCase: any PhotoLibraryUseCaseProtocol,
        shareCollectionUseCase: any ShareCollectionUseCaseProtocol,
        router: some AlbumContentRouting,
        newAlbumPhotosToAdd: [NodeEntity]? = nil,
        alertViewModel: TextFieldAlertViewModel,
        tracker: some AnalyticsTracking = DIContainer.tracker
    ) {
        self.album = album
        self.newAlbumPhotosToAdd = newAlbumPhotosToAdd
        self.albumContentsUseCase = albumContentsUseCase
        self.albumModificationUseCase = albumModificationUseCase
        self.photoLibraryUseCase = photoLibraryUseCase
        self.shareCollectionUseCase = shareCollectionUseCase
        self.router = router
        self.alertViewModel = alertViewModel
        self.tracker = tracker
        
        setupSubscription()
        setupAlbumModification()
    }
    
    // MARK: - Dispatch action
    
    func dispatch(_ action: AlbumContentAction) {
        switch action {
        case .onViewReady:
            tracker.trackAnalyticsEvent(with: AlbumContentScreenEvent())
            loadingTask = Task { @MainActor in
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
            deletePhotosTask = Task { @MainActor in
                await deletePhotos(photos)
            }
        case .deleteAlbum:
            deleteAlbum()
        case .configureContextMenu(let isSelectHidden):
            isPhotoSelectionHidden = isSelectHidden
            invokeCommand?(.rebuildContextMenu)
        case .shareLink:
            tracker.trackAnalyticsEvent(with: AlbumContentShareLinkMenuToolbarEvent())
            router.showShareLink(album: album)
        case .removeLink:
            removeSharedLink()
        case .hideNodes:
            tracker.trackAnalyticsEvent(with: AlbumContentHideNodeMenuItemEvent())
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
            isSelectHidden: isPhotoSelectionHidden,
            isEmptyState: photos.isEmpty,
            sharedLinkStatus: album.sharedLinkStatus
        )
    }
    
    func cancelLoading() {
        loadingTask?.cancel()
        addAdditionalPhotosTask?.cancel()
    }
    
    func showAlbumContentPicker() {
        router.showAlbumContentPicker(album: album, completion: { [weak self] _, albumPhotos in
            self?.addAdditionalPhotos(albumPhotos)
        })
    }
    
    func renameAlbum(with name: String) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            
            do {
                let newName = try await albumModificationUseCase.rename(album: album.id, with: name)
                onAlbumRenameSuccess(with: newName)
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
                doesPhotoLibraryContainPhotos = (try? await photoLibraryUseCase.media(for: [.allMedia, .allLocations], excludeSensitive: nil)
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
            showAlbumPhotos()
            await addPhotos(newAlbumPhotosToAdd)
            self.newAlbumPhotosToAdd = nil
        }
    }
    
    private func addAdditionalPhotos(_ photos: [NodeEntity]) {
        addAdditionalPhotosTask = Task { @MainActor in
            await addPhotos(photos)
        }
    }
    
    @MainActor
    private func addPhotos(_ photos: [NodeEntity]) async {
        let photosToAdd = photos.filter { photo in !self.photos.contains(where: { photo == $0.photo }) }
        guard photosToAdd.isNotEmpty else {
            return
        }
        invokeCommand?(.startLoading)
        do {
            let result = try await albumModificationUseCase.addPhotosToAlbum(by: album.id, nodes: photosToAdd)
            invokeCommand?(.finishLoading)
            if result.success > 0 {
                let message = self.successMessage(forAlbumName: album.name, withNumberOfItmes: result.success)
                invokeCommand?(.showResultMessage(.success(message)))
            }
        } catch {
            invokeCommand?(.finishLoading)
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
        loadingTask = Task { @MainActor in
            await loadNodes()
        }
    }
    
    private func setupSubscription() {
        albumContentsUseCase.albumReloadPublisher(forAlbum: album)
            .debounce(for: .seconds(0.35), scheduler: DispatchQueue.global())
            .sink { [weak self] in
                guard let self else { return }
                reloadAlbum()
            }.store(in: &subscriptions)
        
        if let userAlbumUpdatedPublisher = albumContentsUseCase.userAlbumUpdatedPublisher(for: album) {
            userAlbumUpdatedPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    guard let self else { return }
                    handleUserAlbumUpdate(setEntity: $0)
                }.store(in: &subscriptions)
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
    
    private func setupAlbumModification() {
        alertViewModel.action = { [weak self] newName in
            guard let newName = newName else { return }
            self?.renameAlbum(with: newName)
        }
    }
    
    @MainActor
    private func onAlbumRenameSuccess(with newName: String) {
        album.name = newName
        invokeCommand?(.updateNavigationTitle)
    }
    
    private func updateAlbumCover(albumPhoto: AlbumPhotoEntity) {
        Task { [weak self] in
            guard let self else { return }
            
            do {
                _ = try await self.albumModificationUseCase.updateAlbumCover(album: album.id, withAlbumPhoto: albumPhoto)
                self.album.coverNode = albumPhoto.photo
                
                let message = Strings.Localizable.CameraUploads.Albums.albumCoverUpdated
                self.invokeCommand?(.showResultMessage(.success(message)))
            } catch {
                MEGALogError("Error updating user album cover: \(error.localizedDescription)")
            }
        }
    }
    
    private func showAlbumCoverPicker() {
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
            let result = try await albumModificationUseCase.deletePhotos(in: album.id, photos: photosToDelete)
            if result.success > 0 {
                let message = Strings.Localizable.CameraUploads.Albums.removedItemFrom(Int(result.success))
                    .replacingOccurrences(of: "[A]", with: "\(albumName)")
                invokeCommand?(.showResultMessage(.custom(UIImage.hudMinus, message)))
            }
        } catch {
            MEGALogError("Error occurred when deleting photos for the album. \(error.localizedDescription)")
        }
    }
    
    private func deleteAlbum() {
        deleteAlbumTask = Task { @MainActor in
            let albumIds = await albumModificationUseCase.delete(albums: [album.id])
            
            if albumIds.first == album.id {
                let successMsg = Strings.Localizable.CameraUploads.Albums.deleteAlbumSuccess(1)
                    .replacingOccurrences(of: "[A]", with: albumName)
                invokeCommand?(.dismissAlbum)
                invokeCommand?(.showResultMessage(.custom(UIImage.hudMinus, successMsg)))
            } else {
                MEGALogError("Error occurred when deleting the album id: \(album.id)")
            }
        }
    }
    
    private func handleUserAlbumUpdate(setEntity: SetEntity) {
        if setEntity.changeTypes.contains(.removed) {
            invokeCommand?(.dismissAlbum)
            return
        }
        if setEntity.changeTypes.contains(.name) && albumName != setEntity.name {
            album.name = setEntity.name
            invokeCommand?(.updateNavigationTitle)
        }
        if setEntity.changeTypes.contains(.cover) {
            retriveNewUserAlbumCover(photoId: setEntity.coverId)
        }
        if setEntity.changeTypes.contains(.exported) {
            album.sharedLinkStatus = .exported(setEntity.isExported)
            invokeCommand?(.rebuildContextMenu)
        }
    }

    private func retriveNewUserAlbumCover(photoId: HandleEntity) {
        Task { [weak self] in
            guard let self else { return }
            if let newCover = await albumContentsUseCase.userAlbumCoverPhoto(in: album, forPhotoId: photoId) {
                album.coverNode = newCover
            }
        }
    }
    
    private func removeSharedLink() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await shareCollectionUseCase.removeSharedLink(forAlbum: album)
                invokeCommand?(.showResultMessage(.success(Strings.Localizable.CameraUploads.Albums.removeShareLinkSuccessMessage(1))))
            } catch {
                MEGALogError("Error removing album link for album: \(album.id)")
            }
        }
    }
}
