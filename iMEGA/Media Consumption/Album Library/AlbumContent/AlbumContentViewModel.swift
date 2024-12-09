import Combine
import ContentLibraries
import Foundation
import MEGAAnalyticsiOS
import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGASwiftUI

enum AlbumContentAction: ActionType {
    case onViewReady
    case onViewWillAppear
    case onViewWillDisappear
    case changeSortOrder(SortOrderType)
    case changeFilter(FilterType)
    case showAlbumCoverPicker
    case deletePhotos([NodeEntity])
    case deleteAlbum
    case configureContextMenu(isSelectHidden: Bool)
    case shareLink
    case removeLink
    case hideNodes
    case renameAlbum
}

@MainActor
final class AlbumContentViewModel: ViewModelType {
    enum Command: CommandType {
        case startLoading
        case finishLoading
        case showAlbumPhotos(photos: [NodeEntity], sortOrder: SortOrderType)
        case dismissAlbum
        case showResultMessage(MessageType)
        case updateNavigationTitle
        case showDeleteAlbumAlert
        case configureRightBarButtons(contextMenuConfiguration: CMConfigEntity?, canAddPhotosToAlbum: Bool)
        case showRenameAlbumAlert(viewModel: TextFieldAlertViewModel)
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
    private let monitorAlbumPhotosUseCase: any MonitorAlbumPhotosUseCaseProtocol
    private let tracker: any AnalyticsTracking
    private let albumRemoteFeatureFlagProvider: any AlbumRemoteFeatureFlagProviderProtocol
    private let albumContentDataProvider: any AlbumContentPhotoLibraryDataProviderProtocol
    private let albumNameUseCase: any AlbumNameUseCaseProtocol
    private var loadingTask: Task<Void, Never>?
    private var subscriptions = Set<AnyCancellable>()
    private var selectedSortOrder: SortOrderType = .newest
    private var selectedFilter: FilterType = .allMedia
    private var addAdditionalPhotosTask: Task<Void, Never>?
    private var newAlbumPhotosToAdd: [NodeEntity]?
    private var photoLibraryContainsPhotos: Bool = true
    private var deletePhotosTask: Task<Void, Never>?
    private var deleteAlbumTask: Task<Void, Never>?
    private(set) var setupSubscriptionTask: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }
    private(set) var reloadAlbumTask: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }
    private var showAlbumPhotosTask: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }
    private var updateRightBarButtonsTask: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }
    private var retrieveUserAlbumCover: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }
    private var retrieveAlbumNamesTask: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }
    private var renameAlbumNamesTask: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }
    
    var invokeCommand: ((Command) -> Void)?
    var isPhotoSelectionHidden = false
    
    var albumName: String {
        album.name
    }
    
    // MARK: - Init
    
    init(
        album: AlbumEntity,
        albumContentsUseCase: some AlbumContentsUseCaseProtocol,
        albumModificationUseCase: some AlbumModificationUseCaseProtocol,
        photoLibraryUseCase: some PhotoLibraryUseCaseProtocol,
        shareCollectionUseCase: some ShareCollectionUseCaseProtocol,
        monitorAlbumPhotosUseCase: some MonitorAlbumPhotosUseCaseProtocol,
        albumNameUseCase: some AlbumNameUseCaseProtocol,
        router: some AlbumContentRouting,
        newAlbumPhotosToAdd: [NodeEntity]? = nil,
        tracker: some AnalyticsTracking = DIContainer.tracker,
        albumContentDataProvider: some AlbumContentPhotoLibraryDataProviderProtocol = AlbumContentPhotoLibraryDataProvider(),
        albumRemoteFeatureFlagProvider: some AlbumRemoteFeatureFlagProviderProtocol = AlbumRemoteFeatureFlagProvider()
    ) {
        self.album = album
        self.newAlbumPhotosToAdd = newAlbumPhotosToAdd
        self.albumContentsUseCase = albumContentsUseCase
        self.albumModificationUseCase = albumModificationUseCase
        self.photoLibraryUseCase = photoLibraryUseCase
        self.shareCollectionUseCase = shareCollectionUseCase
        self.monitorAlbumPhotosUseCase = monitorAlbumPhotosUseCase
        self.albumNameUseCase = albumNameUseCase
        self.router = router
        self.tracker = tracker
        self.albumContentDataProvider = albumContentDataProvider
        self.albumRemoteFeatureFlagProvider = albumRemoteFeatureFlagProvider
    }
    
    // MARK: - Dispatch action
    
    func dispatch(_ action: AlbumContentAction) {
        switch action {
        case .onViewReady:
            onViewReady()
        case .onViewWillAppear where setupSubscriptionTask == nil:
            setupAlbumMonitoring()
        case .onViewWillDisappear:
            cancelLoading()
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
        case .deleteAlbum:
            deleteAlbum()
        case .configureContextMenu(let isSelectHidden):
            isPhotoSelectionHidden = isSelectHidden
            updateRightBarButtons()
        case .shareLink:
            tracker.trackAnalyticsEvent(with: AlbumContentShareLinkMenuToolbarEvent())
            router.showShareLink(album: album)
        case .removeLink:
            removeSharedLink()
        case .hideNodes:
            tracker.trackAnalyticsEvent(with: AlbumContentHideNodeMenuItemEvent())
        case .renameAlbum:
            showRenameAlbumAlert()
        default:
            break
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
    
    func showAlbumContentPicker() {
        router.showAlbumContentPicker(album: album, completion: { [weak self] _, albumPhotos in
            self?.addAdditionalPhotos(albumPhotos)
        })
    }
    
    // MARK: Private
    
    private var canAddPhotosToAlbum: Bool {
        album.type == .user && photoLibraryContainsPhotos
    }
    
    private func onViewReady() {
        tracker.trackAnalyticsEvent(with: AlbumContentScreenEvent())
        invokeCommand?(.configureRightBarButtons(
            contextMenuConfiguration: nil, canAddPhotosToAlbum: canAddPhotosToAlbum))
        loadingTask = Task {
            await addNewAlbumPhotosIfNeeded()
            guard !Task.isCancelled else { return }
            await loadNodes()
        }
    }
    
    private func loadNodes() async {
        guard !albumRemoteFeatureFlagProvider.isPerformanceImprovementsEnabled() else { return }
        do {
            let photos = try await albumContentsUseCase.photos(in: album)
            guard !Task.isCancelled else { return }
            await updateAlbumPhotos(photos)
        } catch {
            MEGALogError("Error getting nodes for album: \(error.localizedDescription)")
        }
    }
    
    private func monitorAlbumPhotos() async {
        for await albumPhotosResult in await monitorAlbumPhotosUseCase.monitorPhotos(for: album) {
            switch albumPhotosResult {
            case .success(let albumPhotos):
                await updateAlbumPhotos(albumPhotos)
            case .failure(let error):
                MEGALogError("[\(type(of: self))]: Error getting photos for album id \(album.id) error: \(error.localizedDescription)")
            }
        }
    }
    
    private func updateAlbumPhotos(_ photos: [AlbumPhotoEntity]) async {
        await albumContentDataProvider.updatePhotos(photos)
        guard !Task.isCancelled else { return }
        photoLibraryContainsPhotos = photos.isNotEmpty
        if photos.isEmpty && album.type == .user {
            photoLibraryContainsPhotos = (try? await photoLibraryUseCase.media(for: [.allMedia, .allLocations], excludeSensitive: nil)
                .isNotEmpty) ?? false
        }
        guard !Task.isCancelled else { return }
        let shouldDismissAlbum = photos.isEmpty && [AlbumEntityType.raw, .gif].contains(album.type)
        await shouldDismissAlbum ? invokeCommand?(.dismissAlbum) : showAlbumPhotos()
    }
    
    private func addNewAlbumPhotosIfNeeded() async {
        guard let newAlbumPhotosToAdd else { return }
        await addPhotos(newAlbumPhotosToAdd)
        self.newAlbumPhotosToAdd = nil
    }
    
    private func addAdditionalPhotos(_ photos: [NodeEntity]) {
        addAdditionalPhotosTask = Task {
            await addPhotos(photos)
        }
    }
    
    private func addPhotos(_ photos: [NodeEntity]) async {
        let photosToAdd = await albumContentDataProvider.nodesToAddToAlbum(photos)
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
        showAlbumPhotosTask = Task {
            await showAlbumPhotos()
        }
    }
    
    private func showAlbumPhotos() async {
        let notContainImageAndVideo = await !albumContentDataProvider.containsImageAndVideo()
        guard !Task.isCancelled else { return }
        
        if selectedFilter != .allMedia && notContainImageAndVideo {
            selectedFilter = .allMedia
        }
        await invokeCommand?(.showAlbumPhotos(photos: albumContentDataProvider.photos(for: selectedFilter), sortOrder: selectedSortOrder))
        guard !Task.isCancelled else { return }
        await updateRightBarButtons()
    }
    
    private func reloadAlbum() {
        reloadAlbumTask = Task {
            await loadNodes()
        }
    }
    
    private func setupAlbumMonitoring() {
        setupSubscriptionTask = Task {
            if albumRemoteFeatureFlagProvider.isPerformanceImprovementsEnabled() {
                await monitorAlbumPhotos()
            } else {
                setupSubscription()
            }
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

    private func deletePhotos(_ photos: [NodeEntity]) async {
        let photosToDelete = await albumContentDataProvider.albumPhotosToDelete(from: photos)
        guard photosToDelete.isNotEmpty else {
            return
        }
        do {
            let result = try await albumModificationUseCase.deletePhotos(in: album.id, photos: photosToDelete)
            guard !Task.isCancelled else { return }
            
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
        deleteAlbumTask = Task {
            let albumIds = await albumModificationUseCase.delete(albums: [album.id])
            guard !Task.isCancelled else { return }
            
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
            retrieveNewUserAlbumCover(photoId: setEntity.coverId)
        }
        if setEntity.changeTypes.contains(.exported) {
            album.sharedLinkStatus = .exported(setEntity.isExported)
            updateRightBarButtons()
        }
    }

    private func retrieveNewUserAlbumCover(photoId: HandleEntity) {
        retrieveUserAlbumCover = Task {
            guard let newCover = await albumContentsUseCase.userAlbumCoverPhoto(in: album, forPhotoId: photoId),
                  !Task.isCancelled else { return }
    
            album.coverNode = newCover
        }
    }
    
    private func removeSharedLink() {
        Task {
            do {
                try await shareCollectionUseCase.removeSharedLink(forCollectionId: SetIdentifier(handle: album.id))
                invokeCommand?(.showResultMessage(.success(Strings.Localizable.CameraUploads.Albums.removeShareLinkSuccessMessage(1))))
            } catch {
                MEGALogError("Error removing album link for album: \(album.id)")
            }
        }
    }
    
    private func cancelLoading() {
        loadingTask?.cancel()
        addAdditionalPhotosTask?.cancel()
        deletePhotosTask?.cancel()
        deleteAlbumTask?.cancel()
        setupSubscriptionTask = nil
        showAlbumPhotosTask = nil
        updateRightBarButtonsTask = nil
        retrieveUserAlbumCover = nil
        reloadAlbumTask = nil
        retrieveAlbumNamesTask = nil
        renameAlbumNamesTask = nil
    }
    
    private func updateRightBarButtons() {
        updateRightBarButtonsTask = Task {
            await updateRightBarButtons()
        }
    }
    
    private func updateRightBarButtons() async {
        let config = await makeConfigEntity()
        guard !Task.isCancelled else { return }
        
        invokeCommand?(.configureRightBarButtons(contextMenuConfiguration: config, canAddPhotosToAlbum: canAddPhotosToAlbum))
    }
    
    private func makeConfigEntity() async -> CMConfigEntity? {
        let isPhotosEmpty = await albumContentDataProvider.isEmpty()
        guard !(isPhotosEmpty && isFavouriteAlbum) else { return nil }
        
        guard !Task.isCancelled else { return nil }
        let isFilterEnabled = await isFilterEnabled(isPhotosEmpty: isPhotosEmpty)
        
        return CMConfigEntity(
            menuType: .menu(type: .album),
            sortType: selectedSortOrder.toSortOrderEntity(),
            filterType: selectedFilter.toFilterEntity(),
            albumType: album.type,
            isFilterEnabled: isFilterEnabled,
            isSelectHidden: isPhotoSelectionHidden,
            isEmptyState: isPhotosEmpty,
            sharedLinkStatus: album.sharedLinkStatus
        )
    }
    
    private func isFilterEnabled(isPhotosEmpty: Bool) async -> Bool {
        guard !isPhotosEmpty,
              [AlbumEntityType.gif, .raw].notContains(album.type) else {
            return false
        }
        return await albumContentDataProvider.isFilterEnabled(for: selectedFilter)
    }
    
    private func showRenameAlbumAlert() {
        retrieveAlbumNamesTask = Task { @MainActor in
            let userAlbumNames = await albumNameUseCase.userAlbumNames()
            
            guard !Task.isCancelled else { return }
            
            let alertViewModel = TextFieldAlertViewModel(
                textString: album.name,
                title: Strings.Localizable.rename,
                placeholderText: "",
                affirmativeButtonTitle: Strings.Localizable.rename,
                affirmativeButtonInitiallyEnabled: false,
                destructiveButtonTitle: Strings.Localizable.cancel,
                highlightInitialText: true,
                message: Strings.Localizable.renameNodeMessage,
                action: { [weak self] newName in
                    guard let newName else { return }
                    self?.renameAlbum(with: newName)
                },
                validator: AlbumNameValidator(
                    existingAlbumNames: { userAlbumNames }).rename)
            
            invokeCommand?(.showRenameAlbumAlert(viewModel: alertViewModel))
        }
    }
    
    private func renameAlbum(with name: String) {
        renameAlbumNamesTask = Task {
            do {
                let newName = try await albumModificationUseCase.rename(album: album.id, with: name)
                guard !Task.isCancelled else { return }
                album.name = newName
                invokeCommand?(.updateNavigationTitle)
            } catch {
                MEGALogError("Error renaming user album: \(error.localizedDescription)")
            }
        }
    }
}
