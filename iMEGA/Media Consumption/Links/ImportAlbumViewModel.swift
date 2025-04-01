import Combine
import ContentLibraries
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGADomain
import MEGAL10n
import MEGAPermissions
import MEGASwift
import MEGASwiftUI
import SwiftUI

@MainActor
final class ImportAlbumViewModel: ObservableObject {
    enum Constants {
        static let disabledOpacity = 0.3
    }
    // Private State
    private let publicCollectionUseCase: any PublicCollectionUseCaseProtocol
    private let albumNameUseCase: any AlbumNameUseCaseProtocol
    private let accountStorageUseCase: any AccountStorageUseCaseProtocol
    private let importPublicAlbumUseCase: any ImportPublicAlbumUseCaseProtocol
    private let saveMediaUseCase: any SaveMediaToPhotosUseCaseProtocol
    private let permissionHandler: any DevicePermissionsHandling
    private let tracker: any AnalyticsTracking
    private weak var transferWidgetResponder: (any TransferWidgetResponderProtocol)?
    private let monitorUseCase: any NetworkMonitorUseCaseProtocol
    private let appDelegateRouter: any AppDelegateRouting
    
    private var publicLinkWithDecryptionKey: URL?
    private var subscriptions = Set<AnyCancellable>()
    private var showSnackBarSubscription: AnyCancellable?
    private var renamedAlbum: String?
    private var networkMonitorTask: Task<Void, Never>?
    
    // Public State
    private(set) var importAlbumTask: Task<Void, Never>?
    private(set) var reservedAlbumNames: [String]?
    
    let publicLink: URL
    let photoLibraryContentViewModel: PhotoLibraryContentViewModel
    let showImportToolbarButton: Bool
    
    @Published var publicLinkStatus: AlbumPublicLinkStatus = .none {
        willSet {
            showingDecryptionKeyAlert = newValue == .requireDecryptionKey
            showCannotAccessAlbumAlert = newValue == .invalid
        }
    }
    @Published var publicLinkDecryptionKey = ""
    @Published var showingDecryptionKeyAlert = false
    @Published var showShareLink = false
    @Published var showCannotAccessAlbumAlert = false
    @Published var showImportAlbumLocation = false
    @Published var showStorageQuotaWillExceed = false
    @Published var importFolderLocation: NodeEntity?
    @Published var showRenameAlbumAlert = false
    @Published var showPhotoPermissionAlert = false
    @Published var showNoInternetConnection = false
    @Published private(set) var isSelectionEnabled = false
    @Published private(set) var selectButtonOpacity = 0.0
    @Published private(set) var publicAlbumName: String?
    @Published private(set) var selectionNavigationTitle: String = ""
    @Published private(set) var isToolbarButtonsDisabled = true
    @Published private(set) var showLoading = false
    @Published var snackBar: SnackBar?
    @Published private(set) var isShareLinkButtonDisabled = true
    @Published private(set) var isConnectedToNetworkUntilContentLoaded = true
    
    private var albumLink: String {
        (publicLinkWithDecryptionKey ?? publicLink).absoluteString
    }
    
    private var albumName: String? {
        renamedAlbum ?? publicAlbumName
    }
    
    var shouldShowEmptyAlbumView: Bool {
        publicLinkStatus == .loaded && isAlbumEmpty
    }
    
    var isAlbumEmpty: Bool {
        photoLibraryContentViewModel.library.isEmpty
    }
    
    var shouldShowPhotoLibraryContent: Bool {
        publicLinkStatus == .inProgress || publicLinkStatus == .loaded
    }
    
    var renameAlbumMessage: String {
        Strings.Localizable.AlbumLink.Alert.RenameAlbum.message(publicAlbumName ?? "")
    }
    
    init(publicLink: URL,
         publicCollectionUseCase: some PublicCollectionUseCaseProtocol,
         albumNameUseCase: some AlbumNameUseCaseProtocol,
         accountStorageUseCase: some AccountStorageUseCaseProtocol,
         importPublicAlbumUseCase: some ImportPublicAlbumUseCaseProtocol,
         accountUseCase: some AccountUseCaseProtocol,
         saveMediaUseCase: some SaveMediaToPhotosUseCaseProtocol,
         transferWidgetResponder: (some TransferWidgetResponderProtocol)?,
         permissionHandler: some DevicePermissionsHandling,
         tracker: some AnalyticsTracking,
         monitorUseCase: some NetworkMonitorUseCaseProtocol,
         appDelegateRouter: some AppDelegateRouting) {
        self.publicLink = publicLink
        self.publicCollectionUseCase = publicCollectionUseCase
        self.albumNameUseCase = albumNameUseCase
        self.accountStorageUseCase = accountStorageUseCase
        self.importPublicAlbumUseCase = importPublicAlbumUseCase
        self.saveMediaUseCase = saveMediaUseCase
        self.transferWidgetResponder = transferWidgetResponder
        self.permissionHandler = permissionHandler
        self.tracker = tracker
        self.monitorUseCase = monitorUseCase
        self.appDelegateRouter = appDelegateRouter
        
        photoLibraryContentViewModel = PhotoLibraryContentViewModel(library: PhotoLibrary(),
                                                                    contentMode: .albumLink)
        showImportToolbarButton = accountUseCase.isLoggedIn()
        
        subscribeToSelection()
        subscribeToImportFolderSelection()
        subscribeToHandleAnalytics()
    }
    
    deinit {
        publicCollectionUseCase.stopCollectionLinkPreview()
        networkMonitorTask?.cancel()
        networkMonitorTask = nil
    }
    
    func onViewAppear() {
        tracker.trackAnalyticsEvent(with: DIContainer.albumImportScreenEvent)
    }
    
    func loadPublicAlbum() async {
        publicLinkStatus = .inProgress
        if decryptionKeyRequired() {
            publicLinkStatus = .requireDecryptionKey
        } else {
            await loadPublicAlbumContents()
        }
    }
    
    func loadWithNewDecryptionKey() async {
        guard monitorUseCase.isConnected() else {
            showNoInternetConnection = true
            return
        }
        guard publicLinkDecryptionKey.isNotEmpty,
              let linkWithDecryption = URL(string: publicLink.absoluteString + "#" + publicLinkDecryptionKey) else {
            setLinkToInvalid()
            return
        }
        publicLinkWithDecryptionKey = linkWithDecryption
        await loadPublicAlbum()
    }
    
    func enablePhotoLibraryEditMode(_ enable: Bool) {
        photoLibraryContentViewModel.selection.editMode = enable ? .active : .inactive
    }
    
    func shareLinkTapped() {
        guard validateOverDiskQuota() else {
            return
        }
        showShareLink.toggle()
    }
    
    func selectAllPhotos() {
        photoLibraryContentViewModel.toggleSelectAllPhotos()
    }
    
    func importAlbum() async {
        tracker.trackAnalyticsEvent(with: DIContainer.albumImportSaveToCloudDriveButtonEvent)
        guard validateOverDiskQuota() else {
            return
        }
        guard monitorUseCase.isConnected() else {
            showNoInternetConnection = true
            return
        }
        do {
            try await accountStorageUseCase.refreshCurrentAccountDetails()
        } catch {
            MEGALogError("[Import Album] Error loading account details. Error: \(error)")
            return
        }
        
        guard !accountStorageUseCase.willStorageQuotaExceed(after: photoLibraryContentViewModel.photosToAction) else {
            showStorageQuotaWillExceed.toggle()
            return
        }
        
        guard let publicAlbumName,
              await !isAlbumNameInConflict(publicAlbumName) else {
            showRenameAlbumAlert.toggle()
            return
        }
        showImportAlbumLocation.toggle()
    }
    
    func saveToPhotos() async {
        tracker.trackAnalyticsEvent(with: DIContainer.albumImportSaveToDeviceButtonEvent)
        guard validateOverDiskQuota() else {
            return
        }
        
        guard monitorUseCase.isConnected() else {
            showNoInternetConnection = true
            return
        }
        let photosToSave = photoLibraryContentViewModel.photosToAction
        
        guard photosToSave.isNotEmpty else {
            return
        }
        
        let granted = await permissionHandler.requestPhotoLibraryAccessPermissions()
        
        guard granted else {
            showPhotoPermissionAlert = true
            MEGALogError("[Import Album] PhotoLibraryAccessPermissions not granted")
            return
        }
        
        transferWidgetResponder?.setProgressViewInKeyWindow()
        transferWidgetResponder?.updateProgressView(bottomConstant: -140)
        transferWidgetResponder?.bringProgressToFrontKeyWindowIfNeeded()
        transferWidgetResponder?.showWidgetIfNeeded()
        
        showSnackBar(message: Strings.Localizable.General.SaveToPhotos.started(photosToSave.count))
        
        do {
            try await saveMediaUseCase.saveToPhotos(nodes: photosToSave)
        } catch {
            MEGALogError("[Import Album] Error saving media nodes: \(error)")
            showSnackBar(message: error.localizedDescription)
        }
    }
    
    func renameAlbum(newName: String) {
        guard monitorUseCase.isConnected() else {
            showNoInternetConnection = true
            return
        }
        renamedAlbum = newName
        showImportAlbumLocation.toggle()
    }
    
    func monitorNetworkConnection() {
        let connectionSequence = monitorUseCase.connectionSequence
        
        networkMonitorTask = Task { [weak self] in
            for await isConnected in connectionSequence {
                guard [AlbumPublicLinkStatus.loaded, .invalid].notContains(self?.publicLinkStatus) else {
                    break
                }
                self?.isConnectedToNetworkUntilContentLoaded = isConnected
            }
        }
    }
    
    // MARK: Private
    
    private func isAlbumNameInConflict(_ name: String) async -> Bool {
        let reservedNames = await albumNameUseCase.reservedAlbumNames()
        reservedAlbumNames = reservedNames
        return reservedNames.contains(name)
    }
    
    private func loadPublicAlbumContents() async {
        do {
            let publicAlbum = try await publicCollectionUseCase.publicCollection(forLink: albumLink)
            try Task.checkCancellation()
            publicAlbumName = publicAlbum.set.name
            let photos = await publicCollectionUseCase.publicNodes(publicAlbum.setElements)
            try Task.checkCancellation()
            photoLibraryContentViewModel.library = photos.toPhotoLibrary(withSortType: .modificationDesc)
            publicLinkStatus = .loaded
            tracker.trackAnalyticsEvent(with: DIContainer.importAlbumContentLoadedEvent)
        } catch is CancellationError {
            MEGALogError("[Import Album] loadPublicAlbumContents cancelled")
        } catch {
            setLinkToInvalid()
            MEGALogError("[Import Album] Error retrieving public album. Error: \(error)")
        }
    }
    
    private func decryptionKeyRequired() -> Bool {
        albumLink.components(separatedBy: "#").count == 1
    }
    
    private func setLinkToInvalid() {
        publicLinkStatus = .invalid
        publicLinkWithDecryptionKey = nil
    }
        
    // MARK: Subscriptions
    
    private func subscribeToSelection() {
        subscribeToEditMode()
        subscribeToSelectionHidden()
        
        let selectionCountPublisher = photoLibraryContentViewModel.selection.$photos
            .map { $0.values.count }
        
        selectionCountPublisher
            .removeDuplicates()
            .map {
                switch $0 {
                case 0:
                    return Strings.Localizable.selectTitle
                default:
                    return Strings.Localizable.General.Format.itemsSelected($0)
                }
            }.assign(to: &$selectionNavigationTitle)
        
        let isItemsSelectedPublisher = $isSelectionEnabled.combineLatest(selectionCountPublisher)
            .map { isSelectionEnabled, selectionCount in
                if isSelectionEnabled {
                    return selectionCount == 0
                }
                return false
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
        
        subscribeToPublicLinkStatus(isItemsSelectedPublisher: isItemsSelectedPublisher)
        subscribeToLibraryChange(isItemsSelectedPublisher: isItemsSelectedPublisher)
    }
    
    private func subscribeToPublicLinkStatus(isItemsSelectedPublisher: AnyPublisher<Bool, Never>) {
        $publicLinkStatus.map { status -> AnyPublisher<Bool, Never> in
            guard status == .loaded else {
                return Just(true).eraseToAnyPublisher()
            }
            return isItemsSelectedPublisher
        }
        .switchToLatest()
        .removeDuplicates()
        .assign(to: &$isShareLinkButtonDisabled)
    }
    
    private func subscribeToLibraryChange(isItemsSelectedPublisher: AnyPublisher<Bool, Never>) {
        photoLibraryContentViewModel.$library
            .dropFirst()
            .map(\.isEmpty)
            .removeDuplicates()
            .map { isLibraryEmpty -> AnyPublisher<Bool, Never> in
                guard !isLibraryEmpty else {
                    return Just(true).eraseToAnyPublisher()
                }
                return isItemsSelectedPublisher
            }
            .switchToLatest()
            .removeDuplicates()
            .assign(to: &$isToolbarButtonsDisabled)
    }
    
    private func subscribeToEditMode() {
        photoLibraryContentViewModel.selection.$editMode.map(\.isEditing)
            .removeDuplicates()
            .assign(to: &$isSelectionEnabled)
    }
    
    private func subscribeToSelectionHidden() {
        photoLibraryContentViewModel.$library
            .map(\.isEmpty)
            .combineLatest(photoLibraryContentViewModel.selection.$isHidden)
            .map { isLibraryEmpty, selectionHidden in
                if selectionHidden {
                    return 0.0
                }
                return isLibraryEmpty ? Constants.disabledOpacity : 1
            }
            .removeDuplicates()
            .assign(to: &$selectButtonOpacity)
    }
    
    private func subscribeToHandleAnalytics() {
        $showingDecryptionKeyAlert
            .filter { $0 }
            .sink { [weak self] _ in self?.tracker.trackAnalyticsEvent(with: DIContainer.albumImportInputDecryptionKeyDialogEvent) }
            .store(in: &subscriptions)
    }
    
    private func subscribeToImportFolderSelection() {
        $importFolderLocation
            .compactMap { $0 }
            .sink { [weak self] in
                guard let self else { return }
                handleImportFolderSelection(folder: $0)
            }
            .store(in: &subscriptions)
    }
    
    private func handleImportFolderSelection(folder: NodeEntity) {
        guard monitorUseCase.isConnected() else {
            showNoInternetConnection = true
            return
        }
        guard let albumName else { return }
        let photos = photoLibraryContentViewModel.photosToAction
        
        importAlbumTask = Task { [weak self] in
            guard let self else { return }
            defer { cancelImportAlbumTask() }
            
            toggleLoading()
            do {
                try await importPublicAlbumUseCase.importAlbum(name: albumName,
                                                               photos: photos,
                                                               parentFolder: folder)
                toggleLoading()
                
                let message = isSelectionEnabled ?
                Strings.Localizable.AlbumLink.Alert.Message.filesSaveToCloudDrive(photos.count) :
                Strings.Localizable.AlbumLink.Alert.Message.albumSavedToCloudDrive(albumName)
                showSnackBar(message: message)
            } catch {
                toggleLoading()
                showSnackBar(message: Strings.Localizable.AlbumLink.Alert.Message.albumFailedToSaveToCloudDrive(albumName))
                MEGALogError("[Import Album] Error importing album. Error: \(error)")
            }
        }
    }
    
    private func cancelImportAlbumTask() {
        importAlbumTask?.cancel()
        importAlbumTask = nil
    }
    
    private func showSnackBar(message: String) {
        snackBar = .init(message: message)
    }
    
    private func toggleLoading() {
        showLoading.toggle()
    }
    
    private func validateOverDiskQuota() -> Bool {
        guard !accountStorageUseCase.isPaywalled else {
            enablePhotoLibraryEditMode(false)
            appDelegateRouter.showOverDiskQuota()
            return false
        }
        return true
    }
}

private extension PhotoLibraryContentViewModel {
    var photosToAction: [NodeEntity] {
        if selection.editMode.isEditing {
            return Array(selection.photos.values)
        }
        return library.allPhotos
    }
}

extension ImportAlbumViewModel {
    func renameAlbumAlertViewModel() -> TextFieldAlertViewModel {
        TextFieldAlertViewModel(title: Strings.Localizable.AlbumLink.Alert.RenameAlbum.title,
                                affirmativeButtonTitle: Strings.Localizable.rename,
                                affirmativeButtonInitiallyEnabled: false,
                                destructiveButtonTitle: Strings.Localizable.cancel,
                                message: renameAlbumMessage,
                                action: { [ weak self] in
            guard let self, let newName = $0 else { return }
            renameAlbum(newName: newName)
        },
                                validator: AlbumNameValidator(existingAlbumNames: { [ weak self] in
            guard let self, let reservedAlbumNames else { return [] }
            return reservedAlbumNames
        }).rename)
    }
}
