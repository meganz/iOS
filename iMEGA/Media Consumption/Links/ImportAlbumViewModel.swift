import Combine
import ContentLibraries
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGADomain
import MEGAL10n
import MEGAPermissions
import MEGASwift
import MEGASwiftUI
import MEGAUIComponent
import QuotaWarnings
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
    private let accountUseCase: any AccountUseCaseProtocol
    private weak var transferWidgetResponder: (any TransferWidgetResponderProtocol)?
    private let monitorUseCase: any NetworkMonitorUseCaseProtocol
    private let appDelegateRouter: any AppDelegateRouting
    private let thumbnailLoader: any ThumbnailLoaderProtocol
    private let exportRouter: any AlbumLinkExportRouting
    private let onboardingRouter: any AlbumLinkImportOnboardingRouting
    private let offlineRouter: any AlbumLinkOfflineRouting
    
    private var publicLinkWithDecryptionKey: URL?
    /// The album's nodes as they came off the link, kept so a sort change can re-map the library
    /// without asking for them again.
    private var publicAlbumPhotos: [NodeEntity] = []
    /// Deliberately not persisted: a public link starts on newest-first every time.
    private var photoSortOrder: SortOrderEntity = .modificationDesc
    private var subscriptions = Set<AnyCancellable>()
    private var showSnackBarSubscription: AnyCancellable?
    private var renamedAlbum: String?
    private var networkMonitorTask: Task<Void, Never>?
    
    // Public State
    private(set) var importAlbumTask: Task<Void, Never>?
    private(set) var copyToOfflineTask: Task<Void, Never>?
    private(set) var reservedAlbumNames: [String]?
    
    let publicLink: URL
    let showImportToolbarButton: Bool
    
    private(set) lazy var photoLibraryContentViewModel = PhotoLibraryContentViewModel(
        library: PhotoLibrary(),
        contentMode: .albumLink,
        globalHeaderType: isLinkRevampEnabled ? .sortAndZoom(headerSortViewModel) : .dateAndZoom,
        configuration: PhotoLibraryContentConfiguration(showsViewModePicker: isLinkRevampEnabled)
    )
    
    private lazy var headerSortViewModel = PhotoHeaderSortViewModel(
        config: SortHeaderConfig(
            title: Strings.Localizable.sortTitle,
            options: [MEGAUIComponent.SortOrder.Key.lastModified].sortOptions
        ),
        currentSortOrder: { [weak self] in
            (self?.photoSortOrder ?? .modificationDesc).toUIComponentSortOrderEntity()
        },
        onSortOrderChanged: { [weak self] sortOrder in
            self?.updateSortOrder(sortOrder.toDomainSortOrderEntity())
        }
    )
    
    @Published var publicLinkStatus: AlbumPublicLinkStatus = .none {
        willSet {
            showingDecryptionKeyAlert = newValue == .requireDecryptionKey
        }
    }
    @Published var publicLinkDecryptionKey = ""
    @Published var showingDecryptionKeyAlert = false
    @Published var showInvalidDecryptionKeyAlert = false
    @Published var showShareLink = false
    @Published var showImportAlbumLocation = false
    @Published var showStorageQuotaWillExceed = false
    @Published var showMoreOptions = false
    @Published private(set) var albumCover: Image?

    private var isQuotaWarningsRevampEnabled: Bool {
        DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .iosQuotaWarningsRevamp)
    }
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
    
    /// The link to hand out, which is not always the one the screen was opened with: a link that arrives
    /// without its decryption key gets it back once the user types the key in, and sharing the bare link
    /// would give the recipient something they cannot open.
    var shareableLink: URL {
        publicLinkWithDecryptionKey ?? publicLink
    }
    
    private var albumLink: String {
        shareableLink.absoluteString
    }
    
    private var albumName: String? {
        renamedAlbum ?? publicAlbumName
    }
    
    let isLinkRevampEnabled: Bool
    
    /// The revamp swaps the icon-only bottom toolbar for a single anchored `Save to MEGA` button. Selection
    /// mode keeps the pre-revamp toolbar -- its redesign belongs to a separate ticket.
    var showsAnchoredButtons: Bool {
        isLinkRevampEnabled && !isSelectionEnabled
    }
    
    /// Not gated on the link revamp: `AlbumLinkUnavailableView` draws the legacy layout too. Gating it
    /// left the invalid state with no UI of its own for everyone the flag had not reached -- an album
    /// content view faded to nothing, with only an alert to say what had happened.
    var shouldShowLinkUnavailable: Bool {
        publicLinkStatus == .invalid
    }
    
    var decryptionKeyAlertMessage: String {
        isLinkRevampEnabled
        ? Strings.Localizable.Link.DecryptionKey.Alert.message
        : Strings.Localizable.decryptionKeyAlertMessageForAlbum
    }
    
    var decryptionKeyAlertPlaceholder: String {
        isLinkRevampEnabled ? Strings.Localizable.decryptionKey : ""
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
    
    var shouldShowMoreOptionsButton: Bool {
        isLinkRevampEnabled
    }
    
    /// Save to MEGA is not among them: the sheet only opens outside a selection, which is exactly where the
    /// anchored button already offers it, so a row here would sit under a button saying the same thing.
    ///
    /// Copy to Offline needs an account and is still offered without one, the way the anchored button is:
    /// a row that disappears leaves nothing to explain why, where a tap can send the visitor to sign in.
    var moreOptions: [AlbumLinkMoreOption] {
        [.select, .copyToOffline, .shareLink]
    }
    
    /// The rows follow the buttons they were moved from: the ones that act on the photos wait for photos
    /// to act on, and Share link waits only for the link to resolve.
    ///
    /// Select carries one condition of its own. The zoom bar can put the screen in the year, month or day
    /// view, and none of them can show a selection -- the same reason the select button this sheet
    /// replaced fades out there.
    var disabledMoreOptions: Set<AlbumLinkMoreOption> {
        var disabled = Set<AlbumLinkMoreOption>()
        if isToolbarButtonsDisabled {
            disabled.formUnion([.select, .copyToOffline])
        }
        if photoLibraryContentViewModel.selectedMode != .all {
            disabled.insert(.select)
        }
        if isShareLinkButtonDisabled {
            disabled.insert(.shareLink)
        }
        return disabled
    }
    
    /// Disabled only once every row it opens onto is, so an empty album can still have its link shared.
    var isMoreOptionsButtonDisabled: Bool {
        isToolbarButtonsDisabled && isShareLinkButtonDisabled
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
         appDelegateRouter: some AppDelegateRouting,
         thumbnailLoader: any ThumbnailLoaderProtocol,
         exportRouter: some AlbumLinkExportRouting,
         onboardingRouter: some AlbumLinkImportOnboardingRouting = AlbumLinkImportOnboardingRouter(),
         offlineRouter: some AlbumLinkOfflineRouting,
         remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol = DIContainer.remoteFeatureFlagUseCase) {
        self.publicLink = publicLink
        self.publicCollectionUseCase = publicCollectionUseCase
        self.albumNameUseCase = albumNameUseCase
        self.accountStorageUseCase = accountStorageUseCase
        self.importPublicAlbumUseCase = importPublicAlbumUseCase
        self.saveMediaUseCase = saveMediaUseCase
        self.transferWidgetResponder = transferWidgetResponder
        self.permissionHandler = permissionHandler
        self.tracker = tracker
        self.accountUseCase = accountUseCase
        self.monitorUseCase = monitorUseCase
        self.appDelegateRouter = appDelegateRouter
        self.thumbnailLoader = thumbnailLoader
        self.exportRouter = exportRouter
        self.onboardingRouter = onboardingRouter
        self.offlineRouter = offlineRouter
        isLinkRevampEnabled = remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .iosLinkRevamp)
        
        showImportToolbarButton = accountUseCase.isLoggedIn()
        
        subscribeToSelection()
        subscribeToImportFolderSelection()
        subscribeToHandleAnalytics()
    }
    
    deinit {
        publicCollectionUseCase.stopCollectionLinkPreview()
        networkMonitorTask?.cancel()
        networkMonitorTask = nil
        copyToOfflineTask?.cancel()
        copyToOfflineTask = nil
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
            handleInvalidDecryptionKey()
            return
        }
        publicLinkWithDecryptionKey = linkWithDecryption
        await loadPublicAlbum()
    }
    
    /// Asks for the key again, now that the user has acknowledged the one they typed in is invalid.
    func acknowledgeInvalidDecryptionKey() {
        publicLinkStatus = .requireDecryptionKey
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
    
    /// One entry point for every row of the more options sheet, so the view does not have to know which
    /// action a row stands for.
    func handle(moreOption: AlbumLinkMoreOption) {
        switch moreOption {
        case .select:
            enablePhotoLibraryEditMode(true)
        case .copyToOffline:
            copyToOffline()
        case .shareLink:
            // Shared straight from the sheet's own row, which hands the system share sheet the
            // anchoring it needs on iPad.
            break
        }
    }
    
    func importAlbum() async {
        tracker.trackAnalyticsEvent(with: DIContainer.albumImportSaveToCloudDriveButtonEvent)
        // The anchored button is offered to logged out visitors as well, so there is no cloud drive to
        // pick a destination in yet -- they are sent to sign in first.
        guard accountUseCase.isLoggedIn() else {
            onboardingRouter.showOnboarding()
            return
        }
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
            if isQuotaWarningsRevampEnabled {
                // By right, the ImportAlbumView is SwiftUI view so StorageQuotaDiaglogView can be used with .sheet modifier directly in ImportAlbumView.
                // However, since the the dialog is used in different places with UIKit via QuotaWarningsRouter.
                // QuotaWarningsRouter has a critical logic that skips another dialog presentation when a quota dialog is already visible
                // As a result, QuotaWarningsRouter is used here for that reason.
                QuotaWarningsRouter().presentStorageDialog(
                    severity: .full(.uploadAttempt)
                )
            } else {
                showStorageQuotaWillExceed = true
            }
            return
        }
        
        guard let publicAlbumName,
              await !isAlbumNameInConflict(publicAlbumName) else {
            showRenameAlbumAlert.toggle()
            return
        }
        showImportAlbumLocation.toggle()
    }
    
    /// Saves the photos to the device, through the system share sheet where Save to Files lives.
    ///
    /// Unlike Save to MEGA, this asks nothing of the account: an album link is browsable logged out and the
    /// download behind the export is too, the same way the file link and folder link Download buttons are.
    func exportPhotos() async {
        guard validateOverDiskQuota() else {
            return
        }
        guard monitorUseCase.isConnected() else {
            showNoInternetConnection = true
            return
        }
        let photosToExport = photoLibraryContentViewModel.photosToAction

        guard photosToExport.isNotEmpty else {
            return
        }
        await exportRouter.export(photos: photosToExport)
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
    
    func updateSortOrder(_ newSortOrder: SortOrderEntity) {
        guard photoSortOrder != newSortOrder else { return }
        photoSortOrder = newSortOrder
        applySortOrderToLibrary()
    }
    
    // MARK: Private
    
    private func copyToOffline() {
        // Offline is the account's own storage, so there is nowhere to put the photos yet -- the same
        // reason the anchored Save to MEGA button sends a logged out visitor to sign in first.
        guard accountUseCase.isLoggedIn() else {
            onboardingRouter.showOnboarding()
            return
        }
        guard validateOverDiskQuota() else {
            return
        }
        guard monitorUseCase.isConnected() else {
            showNoInternetConnection = true
            return
        }
        let photos = photoLibraryContentViewModel.photosToAction
        guard photos.isNotEmpty, copyToOfflineTask == nil else {
            return
        }
        
        copyToOfflineTask = Task { [weak self] in
            guard let self else { return }
            defer { cancelCopyToOfflineTask() }
            
            toggleLoading()
            await offlineRouter.copyToOffline(photos: photos)
            toggleLoading()
        }
    }
    
    private func cancelCopyToOfflineTask() {
        copyToOfflineTask?.cancel()
        copyToOfflineTask = nil
    }
    
    private func applySortOrderToLibrary() {
        photoLibraryContentViewModel.library = publicAlbumPhotos.toPhotoLibrary(withSortType: photoSortOrder)
    }
    
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
            publicAlbumPhotos = photos
            applySortOrderToLibrary()
            publicLinkStatus = .loaded
            tracker.trackAnalyticsEvent(
                with: ShareLinkOpenedEvent(
                    linkType: .album,
                    authStatus: accountUseCase.isLoggedIn() ? .loggedin : .loggedout
                )
            )
            tracker.trackAnalyticsEvent(with: DIContainer.importAlbumContentLoadedEvent)
            await loadAlbumCover(set: publicAlbum.set, setElements: publicAlbum.setElements, photos: photos)
        } catch is CancellationError {
            MEGALogError("[Import Album] loadPublicAlbumContents cancelled")
        } catch {
            handleLoadError(error)
            MEGALogError("[Import Album] Error retrieving public album. Error: \(error)")
        }
    }
    
    /// The set names its cover by element rather than by node, so the element is resolved first. An album
    /// whose cover was never set falls back to its first photo, which is what the album cards do.
    private func loadAlbumCover(set: SetEntity, setElements: [SetElementEntity], photos: [NodeEntity]) async {
        let coverNodeId = setElements.first { $0.handle == set.coverId }?.nodeId
        guard let cover = photos.first(where: { $0.handle == coverNodeId }) ?? photos.first else {
            return
        }
        // Annotated so the single-image overload is picked over the protocol's async sequence one.
        let container: (any ImageContaining)? = try? await thumbnailLoader.loadImage(for: cover, type: .thumbnail)
        albumCover = container?.image
    }
    
    private func decryptionKeyRequired() -> Bool {
        albumLink.components(separatedBy: "#").count == 1
    }
    
    private func setLinkToInvalid() {
        publicLinkStatus = .invalid
        publicLinkWithDecryptionKey = nil
    }
    
    /// A key the user typed in does not take them to the unavailable page: they are told the key is
    /// invalid and asked for it again. A key that came embedded in the link does, as there is nothing
    /// for them to correct. Same split as the file link and the folder link.
    private func handleLoadError(_ error: any Error) {
        guard isLinkRevampEnabled,
              didUserEnterDecryptionKey,
              isDecryptionKeyError(error) else {
            setLinkToInvalid()
            return
        }
        handleInvalidDecryptionKey()
    }
    
    private func handleInvalidDecryptionKey() {
        guard isLinkRevampEnabled else {
            setLinkToInvalid()
            return
        }
        publicLinkWithDecryptionKey = nil
        publicLinkDecryptionKey = ""
        showInvalidDecryptionKeyAlert = true
    }
    
    private var didUserEnterDecryptionKey: Bool {
        publicLinkWithDecryptionKey != nil
    }
    
    /// The album the key opens is fetched as a set, which reports a key it could not use either as a
    /// malformed request or as contents it could not decrypt.
    private func isDecryptionKeyError(_ error: any Error) -> Bool {
        guard let error = error as? SharedCollectionErrorEntity else { return false }
        return switch error {
        case .malformed, .couldNotBeReadOrDecrypted: true
        default: false
        }
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
    
    /// The zoom bar the revamp adds brings the year, month and day views with it, and none of them can
    /// show a selection -- so the select button goes away outside the all photos view, the same way the
    /// timeline and media discovery hide theirs through `PhotoLibraryPublisher`.
    private func subscribeToSelectionHidden() {
        photoLibraryContentViewModel.$library
            .map(\.isEmpty)
            .combineLatest(photoLibraryContentViewModel.selection.$isHidden,
                           photoLibraryContentViewModel.$selectedMode)
            .map { isLibraryEmpty, selectionHidden, selectedMode in
                if selectionHidden || selectedMode != .all {
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
