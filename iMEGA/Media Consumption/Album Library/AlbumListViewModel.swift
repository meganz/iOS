import AsyncAlgorithms
import Combine
import ContentLibraries
import MEGAAnalyticsiOS
import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGASwift
import MEGASwiftUI
import SwiftUI

@MainActor
final class AlbumListViewModel: NSObject, ObservableObject {
    @Published var album: AlbumEntity?
    @Published var shouldLoad = true
    @Published var albums = [AlbumEntity]()
    @Published var newlyAddedAlbum: AlbumEntity?
    @Published var albumHudMessage: AlbumHudMessage?
    @Published var albumAlertType: AlbumAlertType?
    @Published var showCreateAlbumAlert = false {
        willSet {
            self.alertViewModel.placeholderText = newAlbumName()
        }
    }
    @Published var showShareAlbumLinks = false
    
    lazy var selection = AlbumSelection()
    
    var createAlbumTask: Task<Void, Never>?
    var deleteAlbumTask: Task<Void, Never>?
    var albumRemoveShareLinkTask: Task<Void, Never>?
    var newAlbumContent: AlbumContent?
    
    var albumNames: [String] {
        albums.map { $0.name }
    }
    
    var selectedUserAlbums: [AlbumEntity] {
        selection.albums.values.filter { $0.type == .user }
    }
    
    private let usecase: any AlbumListUseCaseProtocol
    private let albumModificationUseCase: any AlbumModificationUseCaseProtocol
    private let shareCollectionUseCase: any ShareCollectionUseCaseProtocol
    private let tracker: any AnalyticsTracking
    private let monitorAlbumsUseCase: any MonitorAlbumsUseCaseProtocol
    private let sensitiveDisplayPreferenceUseCase: any SensitiveDisplayPreferenceUseCaseProtocol
    private let albumRemoteFeatureFlagProvider: any AlbumRemoteFeatureFlagProviderProtocol
    private(set) var alertViewModel: TextFieldAlertViewModel
    
    private lazy var albumsSubject = PassthroughSubject<[AlbumEntity], Never>()
    private var subscriptions = Set<AnyCancellable>()
    
    private weak var photoAlbumContainerViewModel: PhotoAlbumContainerViewModel?
    
    init(usecase: some AlbumListUseCaseProtocol,
         albumModificationUseCase: some AlbumModificationUseCaseProtocol,
         shareCollectionUseCase: some ShareCollectionUseCaseProtocol,
         tracker: some AnalyticsTracking,
         monitorAlbumsUseCase: some MonitorAlbumsUseCaseProtocol,
         sensitiveDisplayPreferenceUseCase: some SensitiveDisplayPreferenceUseCaseProtocol,
         alertViewModel: TextFieldAlertViewModel,
         photoAlbumContainerViewModel: PhotoAlbumContainerViewModel? = nil,
         albumRemoteFeatureFlagProvider: some AlbumRemoteFeatureFlagProviderProtocol = AlbumRemoteFeatureFlagProvider()) {
        self.usecase = usecase
        self.albumModificationUseCase = albumModificationUseCase
        self.shareCollectionUseCase = shareCollectionUseCase
        self.tracker = tracker
        self.monitorAlbumsUseCase = monitorAlbumsUseCase
        self.sensitiveDisplayPreferenceUseCase = sensitiveDisplayPreferenceUseCase
        self.alertViewModel = alertViewModel
        self.photoAlbumContainerViewModel = photoAlbumContainerViewModel
        self.albumRemoteFeatureFlagProvider = albumRemoteFeatureFlagProvider
        super.init()
        setupSubscription()
        self.alertViewModel.action = { [weak self] newAlbumName in
            self?.createUserAlbum(with: newAlbumName)
        }
        
        assignAlbumNameValidator()
        subscribeToEditMode()
        subscribeToShareAlbumLinks()
        subscribeToAlbums()
    }
    
    func columns(horizontalSizeClass: UserInterfaceSizeClass?) -> [GridItem] {
        guard let horizontalSizeClass else {
            return Array(
                repeating: .init(.flexible(), spacing: 10),
                count: 3
            )
        }
        return Array(
            repeating: .init(.flexible(), spacing: 10),
            count: horizontalSizeClass == .compact ? 3 : 5
        )
    }
    
    func createUserAlbum(with name: String?) {
        tracker.trackAnalyticsEvent(with: DIContainer.createAlbumDialogButtonPressedEvent)
        guard let name = name else { return }
        guard name.isNotEmpty else {
            createUserAlbum(with: newAlbumName())
            return
        }
        
        photoAlbumContainerViewModel?.disableSelectBarButton = true
        createAlbumTask = Task {
            do {
                let newAlbum = try await usecase.createUserAlbum(with: name)
                
                newlyAddedAlbum = await usecase.hasNoVisualMedia() ? nil : newAlbum
                photoAlbumContainerViewModel?.shouldShowSelectBarButton = true
            } catch {
                MEGALogError("Error creating user album: \(error.localizedDescription)")
            }
            photoAlbumContainerViewModel?.disableSelectBarButton = false
        }
    }
    
    func onCreateAlbum() {
        tracker.trackAnalyticsEvent(with: DIContainer.createNewAlbumDialogEvent)
        guard selection.editMode.isEditing == false else { return }
        showCreateAlbumAlert.toggle()
    }
    
    func showAlertView(_ albumAlertType: AlbumAlertType) -> Alert {
        switch albumAlertType {
        case .deleteAlbum:
            return deleteAlbumAlertView()
        case .removeAlbumShareLink:
            return removeShareLinkAlertView()
        }
    }
    
    func onAlbumListDeleteConfirm() {
        deleteAlbumTask = Task {
            let albumIds = await albumModificationUseCase.delete(albums: Array(selection.albums.keys))
            onAlbumDeleteSuccess(albumIds)
        }
    }
    
    func onAlbumShareLinkRemoveConfirm(_ albums: [AlbumEntity]) {
        albumRemoveShareLinkTask = Task { [weak self] in
            guard let self else { return }
            
            defer { cancelAlbumRemoveShareLinkTask() }
            
            let removeLinkAlbumIds = Set(albums.map { SetIdentifier(handle: $0.id) })
            let successfullyRemoveLinkAlbumIds = await shareCollectionUseCase.removeSharedLink(forCollections: albums.map { SetIdentifier(handle: $0.id) })
            let diff = Set(removeLinkAlbumIds).subtracting(Set(successfullyRemoveLinkAlbumIds))
            
            if diff.count == 0 {
                onRemoveAlbumShareLinkSuccess(successfullyRemoveLinkAlbumIds.map { HandleEntity($0.handle) })
            } else if diff.count < removeLinkAlbumIds.count {
                onRemoveAlbumShareLinkSuccess(successfullyRemoveLinkAlbumIds.map { HandleEntity($0.handle) })
                MEGALogError("Albums [\(diff)] share link can not be removed")
            } else {
                MEGALogError("Albums [\(diff)] share link can not be removed")
            }
        }
    }
    
    func onViewDisappear() {
        setEditModeToInactive()
        cancelCreateAlbumTask()
    }
    
    func setEditModeToInactive() {
        photoAlbumContainerViewModel?.editMode = .inactive
    }
    
    // MARK: - Private
    private func loadAlbums() async throws {
        shouldLoad = albums.isEmpty
        async let systemAlbums = systemAlbums()
        async let userAlbums = userAlbums()
        try Task.checkCancellation()
        albums = await systemAlbums + userAlbums
        shouldLoad = false
    }
    
    private func systemAlbums() async -> [AlbumEntity] {
        do {
            return try await usecase.systemAlbums().map { album in
                if let localizedAlbumName = album.type.localizedAlbumName {
                    var album = album
                    album.name = localizedAlbumName
                    return album
                }
                return album
            }
        } catch {
            MEGALogError("Error loading system albums: \(error.localizedDescription)")
            return []
        }
    }
    
    private func userAlbums() async -> [AlbumEntity] {
        var userAlbums = await usecase.userAlbums()
        photoAlbumContainerViewModel?.shouldShowSelectBarButton = userAlbums.isNotEmpty
        userAlbums.sort { $0.creationTime ?? Date.distantPast > $1.creationTime ?? Date.distantPast }
        return userAlbums
    }
    
    private func assignAlbumNameValidator() {
        alertViewModel.validator = AlbumNameValidator(
            existingAlbumNames: { [weak self] in
                self?.albumNames ?? []
            }).create
    }
    
    private func onAlbumDeleteSuccess(_ albumIds: [HandleEntity]) {
        guard albumIds.count > 0 else {
            photoAlbumContainerViewModel?.editMode = .inactive
            return
        }
        
        var hudMessage = ""
        if albumIds.count == 1,
           let albumId = albumIds.first,
           let albumName = Array(selection.albums.values).first(where: { $0.id == albumId })?.name {
            hudMessage = Strings.Localizable.CameraUploads.Albums.deleteAlbumSuccess(1).replacingOccurrences(of: "[A]", with: albumName)
        } else {
            hudMessage = Strings.Localizable.CameraUploads.Albums.deleteAlbumSuccess(albumIds.count)
        }
        photoAlbumContainerViewModel?.editMode = .inactive
        albumHudMessage = AlbumHudMessage(message: hudMessage, icon: UIImage.hudMinus)
    }
    
    private func onRemoveAlbumShareLinkSuccess(_ albumIds: [HandleEntity]) {
        guard albumIds.count > 0 else {
            photoAlbumContainerViewModel?.editMode = .inactive
            return
        }
        
        let hudMessage = albumIds.count == 1 ? Strings.Localizable.CameraUploads.Albums.removeShareLinkSuccessMessage(1) : Strings.Localizable.CameraUploads.Albums.removeShareLinkSuccessMessage(albums.count)
        albumHudMessage = AlbumHudMessage(message: hudMessage, icon: UIImage.hudSuccess)
        
        photoAlbumContainerViewModel?.editMode = .inactive
    }
    
    private func deleteAlbumAlertView() -> Alert {
        Alert(
            title: Text(Strings.Localizable.CameraUploads.Albums.deleteAlbumTitle(selection.albums.count)),
            message: Text(Strings.Localizable.CameraUploads.Albums.deleteAlbumMessage(selection.albums.count)),
            primaryButton: .default(Text(Strings.Localizable.delete)) { [weak self] in
                self?.onAlbumListDeleteConfirm()
            },
            secondaryButton: .cancel(Text(Strings.Localizable.cancel))
        )
    }
    
    private func removeShareLinkAlertView() -> Alert {
        Alert(
            title: Text(Strings.Localizable.CameraUploads.Albums.removeShareLinkAlertTitle(selection.albums.count)),
            message: Text(Strings.Localizable.CameraUploads.Albums.removeShareLinkAlertMessage(selection.albums.count)),
            primaryButton: .default(Text(Strings.Localizable.CameraUploads.Albums.removeShareLinkAlertConfirmButtonTitle(selection.albums.count))) { [weak self] in
                guard let self else { return }
                onAlbumShareLinkRemoveConfirm(Array(selection.albums.values))
            },
            secondaryButton: .cancel(Text(Strings.Localizable.cancel))
        )
    }
    
    func newAlbumName() -> String {
        albums.map(\.name)
            .newAlbumName()
    }
    
    func onNewAlbumContentAdded(_ album: AlbumEntity, photos: [NodeEntity]) {
        tracker.trackAnalyticsEvent(with: DIContainer.addItemsToNewAlbumButtonEvent)
        newAlbumContent = AlbumContent(album: album, photos: photos)
    }
    
    func navigateToNewAlbum() {
        album = newAlbumContent?.album
        album?.count = newAlbumContent?.photos?.count ?? 0
        album?.coverNode = newAlbumContent?.photos?.sorted { $0.modificationTime > $1.modificationTime }.first
    }
    
    func monitorAlbums() async throws {
        guard !albumRemoteFeatureFlagProvider.isPerformanceImprovementsEnabled() else {
            await newAlbumMonitoring()
            return
        }
        let albumsUpdatedStream = usecase
            .albumsUpdatedPublisher
            .prepend(())
            .debounceImmediate(for: .seconds(0.35), scheduler: DispatchQueue.global())
            .eraseToAnyPublisher()
            .values
        
        for await _ in albumsUpdatedStream {
            try Task.checkCancellation()
            try await loadAlbums()
        }
    }
    
    // MARK: - Private
    
    private func setupSubscription() {
        
        photoAlbumContainerViewModel?.$showDeleteAlbumAlert
            .dropFirst()
            .sink { [weak self] _ in
                guard let self else { return }
                albumAlertType = .deleteAlbum
            }
            .store(in: &subscriptions)
        
        photoAlbumContainerViewModel?.$showRemoveAlbumLinksAlert
            .dropFirst()
            .sink { [weak self] _ in
                guard let self else { return }
                albumAlertType = .removeAlbumShareLink
            }
            .store(in: &subscriptions)
        
        if let photoAlbumContainerViewModel {
            selection.isAlbumSelectedPublisher
                .assign(to: &photoAlbumContainerViewModel.$isAlbumsSelected)
            selection.isExportedAlbumSelectedPublisher
                .assign(to: &photoAlbumContainerViewModel.$isExportedAlbumSelected)
            selection.isOnlyExportedAlbumsSelectedPublisher
                .assign(to: &photoAlbumContainerViewModel.$isOnlyExportedAlbumsSelected)
        }
    }
    
    private func subscribeToEditMode() {
        photoAlbumContainerViewModel?.$editMode
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] in
                self?.selection.editMode = $0
            })
            .store(in: &subscriptions)
    }
    
    private func cancelAlbumRemoveShareLinkTask() {
        albumRemoveShareLinkTask?.cancel()
        albumRemoveShareLinkTask = nil
    }
    
    private func subscribeToShareAlbumLinks() {
        guard let photoAlbumContainerViewModel else { return }
        photoAlbumContainerViewModel.$showShareAlbumLinks
            .dropFirst()
            .assign(to: &$showShareAlbumLinks)
    }
    
    private func cancelCreateAlbumTask() {
        createAlbumTask?.cancel()
        createAlbumTask = nil
    }
    
    private func newAlbumMonitoring() async {
        let excludeSensitives = await sensitiveDisplayPreferenceUseCase.excludeSensitives()
        for await (systemAlbums, userAlbums) in combineLatest(await monitorSystemAlbums(excludeSensitives: excludeSensitives),
                                                              await monitorUserAlbums(excludeSensitives: excludeSensitives)) {
            updateSelectBarButton(shouldShow: userAlbums.isNotEmpty)
            updateAlbums(systemAlbums + userAlbums)
        }
    }
    
    @MainActor
    private func updateAlbums(_ newAlbums: [AlbumEntity]) {
        albumsSubject.send(newAlbums)
        
        guard shouldLoad else { return }
        shouldLoad.toggle()
    }
    
    private func monitorSystemAlbums(excludeSensitives: Bool) async -> AnyAsyncSequence<[AlbumEntity]> {
         await monitorAlbumsUseCase.monitorLocalizedSystemAlbums(excludeSensitives: excludeSensitives)
            .map {
                switch $0 {
                case .success(let albums):
                    return albums
                case .failure(let error):
                    MEGALogError("[Album List] Failed to retrieve system albums: \(error.localizedDescription)")
                    return []
                }
            }
            .eraseToAnyAsyncSequence()
    }
    
    private func monitorUserAlbums(excludeSensitives: Bool) async -> AnyAsyncSequence<[AlbumEntity]> {
        await monitorAlbumsUseCase.monitorSortedUserAlbums(
            excludeSensitives: excludeSensitives,
            by: { $0.creationTime ?? Date.distantPast > $1.creationTime ?? Date.distantPast })
    }
    
    // Throttle is not available in swift-async-algorithms package and will most likely only be available for iOS 16 and above due to the use of `Clock`.
    private func subscribeToAlbums() {
        guard albumRemoteFeatureFlagProvider.isPerformanceImprovementsEnabled() else { return }
        
        albumsSubject
            .debounceImmediate(for: .seconds(0.3), scheduler: DispatchQueue.main)
            .assign(to: &$albums)
    }
    
    @MainActor
    private func updateSelectBarButton(shouldShow: Bool) {
        guard photoAlbumContainerViewModel?.shouldShowSelectBarButton != shouldShow else { return }
        photoAlbumContainerViewModel?.shouldShowSelectBarButton = shouldShow
    }
}
