import Combine
import SwiftUI
import MEGADomain

@MainActor
final class AlbumListViewModel: NSObject, ObservableObject {
    @Published var cameraUploadNode: NodeEntity?
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
    
    var albumCreationAlertMsg: String?
    var albumLoadingTask: Task<Void, Never>?
    var createAlbumTask: Task<Void, Never>?
    var deleteAlbumTask: Task<Void, Never>?
    var albumRemoveShareLinkTask: Task<Void, Never>?
    var newAlbumContent: (AlbumEntity, [NodeEntity]?)?
    
    var albumNames: [String] {
        albums.map { $0.name }
    }
    
    var selectedUserAlbums: [AlbumEntity] {
        selection.albums.values.filter { $0.type == .user }
    }
    
    private let usecase: AlbumListUseCaseProtocol
    private let albumModificationUseCase: AlbumModificationUseCaseProtocol
    private let shareAlbumUseCase: ShareAlbumUseCaseProtocol
    private(set) var alertViewModel: TextFieldAlertViewModel
    private var subscriptions = Set<AnyCancellable>()
    
    private weak var photoAlbumContainerViewModel: PhotoAlbumContainerViewModel?
    
    init(usecase: AlbumListUseCaseProtocol,
         albumModificationUseCase: AlbumModificationUseCaseProtocol,
         shareAlbumUseCase: ShareAlbumUseCaseProtocol,
         alertViewModel: TextFieldAlertViewModel,
         photoAlbumContainerViewModel: PhotoAlbumContainerViewModel? = nil) {
        self.usecase = usecase
        self.albumModificationUseCase = albumModificationUseCase
        self.shareAlbumUseCase = shareAlbumUseCase
        self.alertViewModel = alertViewModel
        self.photoAlbumContainerViewModel = photoAlbumContainerViewModel
        super.init()
        setupSubscription()
        self.alertViewModel.action = { [weak self] newAlbumName in
            self?.createUserAlbum(with: newAlbumName)
        }
        
        assignAlbumNameValidator()
        subscribeToEditMode()
        subscibeToShareAlbumLinks()
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
    
    func loadAlbums() {
        albumLoadingTask = Task {
            async let systemAlbums = systemAlbums()
            async let userAlbums = userAlbums()
            albums = await systemAlbums + userAlbums
            shouldLoad = false
        }
    }
    
    func cancelLoading() {
        albumLoadingTask?.cancel()
        createAlbumTask?.cancel()
    }
    
    func createUserAlbum(with name: String?) {
        guard let name = name else { return }
        guard name.isNotEmpty else {
            createUserAlbum(with: newAlbumName())
            return
        }
        
        photoAlbumContainerViewModel?.disableSelectBarButton = true
        shouldLoad = true
        createAlbumTask = Task {
            do {
                let newAlbum = try await usecase.createUserAlbum(with: name)

                newlyAddedAlbum = await usecase.hasNoPhotosAndVideos() ? nil : newAlbum
                photoAlbumContainerViewModel?.shouldShowSelectBarButton = true
            } catch {
                MEGALogError("Error creating user album: \(error.localizedDescription)")
            }
            shouldLoad = false
            photoAlbumContainerViewModel?.disableSelectBarButton = false
        }
    }
    
    func onCreateAlbum() {
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
            
            let removeLinkAlbumIds = Set(albums.map { $0.id })
            let successfullyRemoveLinkAlbumIds = await shareAlbumUseCase.removeSharedLink(forAlbums: albums)
            let diff = Set(removeLinkAlbumIds).subtracting(Set(successfullyRemoveLinkAlbumIds))
            
            if diff.count == 0 {
                onRemoveAlbumShareLinkSuccess(successfullyRemoveLinkAlbumIds)
            } else if diff.count < removeLinkAlbumIds.count {
                onRemoveAlbumShareLinkSuccess(successfullyRemoveLinkAlbumIds)
                MEGALogError("Albums [\(diff)] share link can not be removed")
            } else {
                MEGALogError("Albums [\(diff)] share link can not be removed")
            }
        }
    }
    
    // MARK: - Private
    private func systemAlbums() async -> [AlbumEntity] {
        do {
            return try await usecase.systemAlbums().map({ album in
                if let localizedAlbumName = localisedName(forAlbumType: album.type) {
                    return album.update(name: localizedAlbumName)
                }
                return album
            })
        } catch {
            MEGALogError("Error loading system albums: \(error.localizedDescription)")
            return []
        }
    }
    
    private func localisedName(forAlbumType albumType: AlbumEntityType) -> String? {
        switch albumType {
        case .favourite:
            return Strings.Localizable.CameraUploads.Albums.Favourites.title
        case .gif:
            return Strings.Localizable.CameraUploads.Albums.Gif.title
        case .raw:
            return Strings.Localizable.CameraUploads.Albums.Raw.title
        default:
            return nil
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
        albumHudMessage = AlbumHudMessage(message: hudMessage, icon: Asset.Images.Hud.hudMinus.image)
    }
    
    private func onRemoveAlbumShareLinkSuccess(_ albumIds: [HandleEntity]) {
        guard albumIds.count > 0 else {
            photoAlbumContainerViewModel?.editMode = .inactive
            return
        }
        
        let hudMessage = albumIds.count == 1 ? Strings.Localizable.CameraUploads.Albums.removeShareLinkSuccessMessage(1) : Strings.Localizable.CameraUploads.Albums.removeShareLinkSuccessMessage(albums.count)
        albumHudMessage = AlbumHudMessage(message: hudMessage, icon: Asset.Images.Hud.hudSuccess.image)

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
                guard let self = self else { return }
                onAlbumShareLinkRemoveConfirm(Array(selection.albums.values))
            },
            secondaryButton: .cancel(Text(Strings.Localizable.cancel))
        )
    }

    func newAlbumName() -> String {
        let newAlbumName = Strings.Localizable.CameraUploads.Albums.Create.Alert.placeholder
        let names = Set(albums.filter { $0.name.hasPrefix(newAlbumName) }.map { $0.name })
        
        guard names.count > 0 else { return newAlbumName }
        guard names.contains(newAlbumName) else { return newAlbumName }
        
        for i in 1...names.count {
            let newName = "\(newAlbumName) (\(i))"
            if !names.contains(newName) {
                return newName
            }
        }
        return newAlbumName
    }
    
    func onNewAlbumContentAdded(_ album: AlbumEntity, photos: [NodeEntity]) {
        newAlbumContent = (album, photos)
    }
    
    func navigateToNewAlbum() {
        album = newAlbumContent?.0
    }
    
    @MainActor
    func onAlbumTap(_ album: AlbumEntity) {
        guard selection.editMode.isEditing == false else { return }
        
        albumCreationAlertMsg = nil
        self.album = album
    }
    
    // MARK: - Private
    
    private func setupSubscription() {
        usecase.albumsUpdatedPublisher
            .debounce(for: .seconds(0.35), scheduler: DispatchQueue.global())
            .sink { [weak self] in
                self?.loadAlbums()
            }.store(in: &subscriptions)
        
        photoAlbumContainerViewModel?.$showDeleteAlbumAlert
            .dropFirst()
            .sink { [weak self] _ in
                guard let self = self else { return }
                albumAlertType = .deleteAlbum
            }
            .store(in: &subscriptions)
        
        photoAlbumContainerViewModel?.$showRemoveAlbumLinksAlert
            .dropFirst()
            .sink { [weak self] _ in
                guard let self = self else { return }
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
    
    private func subscibeToShareAlbumLinks() {
        guard let photoAlbumContainerViewModel else { return }
        photoAlbumContainerViewModel.$showShareAlbumLinks
            .dropFirst()
            .assign(to: &$showShareAlbumLinks)
    }
}
