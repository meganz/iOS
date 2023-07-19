import Combine
import MEGADomain
import MEGASwift
import SwiftUI

final class ImportAlbumViewModel: ObservableObject {
    enum Constants {
        static let disabledOpacity = 0.3
    }
    private let publicAlbumUseCase: any PublicAlbumUseCaseProtocol
    private var publicLinkWithDecryptionKey: URL?
    
    let publicLink: URL
    let photoLibraryContentViewModel: PhotoLibraryContentViewModel
    
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
    @Published var importFolderLocation: NodeEntity?
    @Published private(set) var isSelectionEnabled = false
    @Published private(set) var selectButtonOpacity = 0.0
    @Published private(set) var albumName: String?
    @Published private(set) var selectionNavigationTitle: String = ""
    @Published private(set) var isToolbarButtonsDisabled = true
    
    private var albumLink: String {
        (publicLinkWithDecryptionKey ?? publicLink).absoluteString
    }
    
    var isPhotosLoaded: Bool {
        publicLinkStatus == .loaded
    }
    
    init(publicLink: URL,
         publicAlbumUseCase: some PublicAlbumUseCaseProtocol) {
        self.publicLink = publicLink
        self.publicAlbumUseCase = publicAlbumUseCase
        
        photoLibraryContentViewModel = PhotoLibraryContentViewModel(library: PhotoLibrary(),
                                                                    contentMode: .albumLink)
        subscribeToSelection()
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
                MEGALogError("Error retrieving public album: \(error.localizedDescription)")
            } catch {
                MEGALogError("Error retrieving public album: \(error.localizedDescription)")
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
}
