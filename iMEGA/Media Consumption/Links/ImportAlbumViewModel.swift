import Combine
import MEGADomain
import MEGASwift
import SwiftUI

final class ImportAlbumViewModel: ObservableObject {
    enum Constants {
        static let disabledOpacity = 0.3
    }
    private let publicAlbumUseCase: any PublicAlbumUseCaseProtocol
    private let albumNameUseCase: any AlbumNameUseCaseProtocol
    private let accountStorageUseCase: any AccountStorageUseCaseProtocol
    private let importPublicAlbumUseCase: any ImportPublicAlbumUseCaseProtocol
    
    private var publicLinkWithDecryptionKey: URL?
    private var subscriptions = Set<AnyCancellable>()
    private var showSnackBarSubscription: AnyCancellable?
    private var snackBarMessage = ""
    
    let publicLink: URL
    let photoLibraryContentViewModel: PhotoLibraryContentViewModel
    let showImportToolbarButton: Bool
    
    @Published var publicLinkStatus: AlbumPublicLinkStatus = .none {
        willSet {
            showingDecryptionKeyAlert = newValue == .requireDecryptionKey
            showCannotAccessAlbumAlert = newValue == .invalid
            showLoading = newValue == .inProgress
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
    @Published var showSnackBar = false
    @Published private(set) var isSelectionEnabled = false
    @Published private(set) var selectButtonOpacity = 0.0
    @Published private(set) var albumName: String?
    @Published private(set) var selectionNavigationTitle: String = ""
    @Published private(set) var isToolbarButtonsDisabled = true
    @Published private(set) var showLoading = false
    
    private var albumLink: String {
        (publicLinkWithDecryptionKey ?? publicLink).absoluteString
    }
    
    var isPhotosLoaded: Bool {
        publicLinkStatus == .loaded
    }
    
    init(publicLink: URL,
         publicAlbumUseCase: some PublicAlbumUseCaseProtocol,
         albumNameUseCase: some AlbumNameUseCaseProtocol,
         accountStorageUseCase: some AccountStorageUseCaseProtocol,
         importPublicAlbumUseCase: some ImportPublicAlbumUseCaseProtocol,
         accountUseCase: some AccountUseCaseProtocol) {
        self.publicLink = publicLink
        self.publicAlbumUseCase = publicAlbumUseCase
        self.albumNameUseCase = albumNameUseCase
        self.accountStorageUseCase = accountStorageUseCase
        self.importPublicAlbumUseCase = importPublicAlbumUseCase
        
        photoLibraryContentViewModel = PhotoLibraryContentViewModel(library: PhotoLibrary(),
                                                                    contentMode: .albumLink)
        showImportToolbarButton = accountUseCase.isLoggedIn()
        
        subscribeToSelection()
        subscibeToImportFolderSelection()
    }
    
    func loadPublicAlbum() {
        publicLinkStatus = .inProgress
        if decryptionKeyRequired() {
            publicLinkStatus = .requireDecryptionKey
        } else {
            loadPublicAlbumContents()
        }
    }
    
    func loadWithNewDecryptionKey() {
        guard publicLinkDecryptionKey.isNotEmpty,
              let linkWithDecryption = URL(string: publicLink.absoluteString + "#" + publicLinkDecryptionKey) else {
            setLinkToInvalid()
            return
        }
        publicLinkWithDecryptionKey = linkWithDecryption
        loadPublicAlbum()
    }
    
    func enablePhotoLibraryEditMode(_ enable: Bool) {
        photoLibraryContentViewModel.selection.editMode = enable ? .active : .inactive
    }
    
    func shareLinkTapped() {
        showShareLink.toggle()
    }
    
    func selectAllPhotos() {
        photoLibraryContentViewModel.toggleSelectAllPhotos()
    }
    
    func importAlbum() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            
            do {
                try await accountStorageUseCase.refreshCurrentAccountDetails()
            } catch {
                MEGALogError("[Import Album] Error loading account details. Error: \(error)")
                return
            }
            
            guard !accountStorageUseCase.willStorageQuotaExceed(after: photoLibraryContentViewModel.photosToImport) else {
                showStorageQuotaWillExceed.toggle()
                return
            }
            
            guard let albumName,
                  await !isAlbumNameInConflict(albumName) else {
                showRenameAlbumAlert.toggle()
                return
            }
            showImportAlbumLocation.toggle()
        }
    }
    
    func snackBarViewModel() -> SnackBarViewModel {
        let snackBar = SnackBar(message: snackBarMessage)
        let viewModel = SnackBarViewModel(snackBar: snackBar)
        
        showSnackBarSubscription = viewModel.$isShowSnackBar
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isShown in
                guard let self else { return }
                if isShown {
                    snackBarMessage = ""
                }
                showSnackBar = isShown
            }
        
        return viewModel
    }
    
    private func isAlbumNameInConflict(_ name: String) async -> Bool {
        await albumNameUseCase.reservedAlbumNames().contains(name)
    }
    
    private func loadPublicAlbumContents() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let publicAlbum = try await publicAlbumUseCase.publicAlbum(forLink: albumLink)
                try Task.checkCancellation()
                albumName = publicAlbum.set.name
                let photos = await publicAlbumUseCase.publicPhotos(publicAlbum.setElements)
                try Task.checkCancellation()
                photoLibraryContentViewModel.library = photos.toPhotoLibrary(withSortType: .newest)
                publicLinkStatus = .loaded
            } catch let error as SharedAlbumErrorEntity {
                setLinkToInvalid()
                MEGALogError("[Import Album] Error retrieving public album. Error: \(error)")
            } catch {
                MEGALogError("[Import Album] Error retrieving public album. Error: \(error)")
            }
        }
    }
    
    private func decryptionKeyRequired() -> Bool {
        albumLink.components(separatedBy: "#").count == 1
    }
    
    private func setLinkToInvalid() {
        publicLinkStatus = .invalid
        publicLinkWithDecryptionKey = nil
    }
    
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
                case 1:
                    return Strings.Localizable.oneItemSelected(1)
                default:
                    return Strings.Localizable.itemsSelected($0)
                }
            }.assign(to: &$selectionNavigationTitle)
        
        $publicLinkStatus.map { [weak self] status -> AnyPublisher<Bool, Never> in
            guard let self else {
                return Empty().eraseToAnyPublisher()
            }
            guard status == .loaded else {
                return Just(true).eraseToAnyPublisher()
            }
            return $isSelectionEnabled.combineLatest(selectionCountPublisher)
                .map { isSelectionEnabled, selectionCount in
                    if isSelectionEnabled {
                        return selectionCount == 0
                    }
                    return false
                }
                .removeDuplicates()
                .eraseToAnyPublisher()
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
        $publicLinkStatus.combineLatest(photoLibraryContentViewModel.selection.$isHidden)
            .map { linkStatus, selectionHidden in
                if selectionHidden {
                    return 0.0
                }
                return linkStatus == .loaded ? 1 : Constants.disabledOpacity
            }
            .removeDuplicates()
            .assign(to: &$selectButtonOpacity)
    }
    
    private func subscibeToImportFolderSelection() {
        $importFolderLocation
            .compactMap { $0 }
            .sink { [weak self] in
                guard let self else { return }
                handeImportFolderSelection(folder: $0)
            }
            .store(in: &subscriptions)
    }
    
    private func handeImportFolderSelection(folder: NodeEntity) {
        guard let albumName else { return }
        let photos = photoLibraryContentViewModel.photosToImport
        
        Task {
            await toggleLoading()
            do {
                try await importPublicAlbumUseCase.importAlbum(name: albumName,
                                                               photos: photos,
                                                               parentFolder: folder)
                await toggleLoading()
                
                let message = isSelectionEnabled ?
                    Strings.Localizable.AlbumLink.Alert.Message.filesSaveToCloudDrive(photos.count) :
                    Strings.Localizable.AlbumLink.Alert.Message.albumSavedToCloudDrive(albumName)
                await showSnackBar(message: message)
            } catch {
                await toggleLoading()
                await showSnackBar(message: Strings.Localizable.AlbumLink.Alert.Message.albumFailedToSaveToCloudDrive(albumName))
                MEGALogError("[Import Album] Error importing album. Error: \(error)")
            }
        }
    }
    
    @MainActor
    private func showSnackBar(message: String) {
        snackBarMessage = message
        showSnackBar.toggle()
    }
    
    @MainActor
    private func toggleLoading() {
        showLoading.toggle()
    }
}

private extension PhotoLibraryContentViewModel {
    var photosToImport: [NodeEntity] {
        if selection.editMode.isEditing {
            return Array(selection.photos.values)
        }
        return library.allPhotos
    }
}
