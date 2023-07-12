import Combine
import MEGADomain
import MEGASwift
import SwiftUI

final class ImportAlbumViewModel: ObservableObject {
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
    @Published var showCannotAccessAlbumAlert = false
    @Published private(set) var isSelectionEnabled = false
    @Published var showShareLink = false
    
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
        photoLibraryContentViewModel.selection.$editMode.map(\.isEditing)
            .removeDuplicates()
            .assign(to: &$isSelectionEnabled)
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
    
    private func loadPublicAlbumContents() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let photos = try await publicAlbumUseCase.publicPhotos(forLink: albumLink)
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
}
