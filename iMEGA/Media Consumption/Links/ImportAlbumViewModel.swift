import Combine
import MEGADomain
import MEGASwift
import SwiftUI

final class ImportAlbumViewModel: ObservableObject {
    @Published var publicLinkStatus: AlbumPublicLinkStatus = .none {
        willSet {
            showingDecryptionKeyAlert = newValue == .requireDecryptionKey
            showCannotAccessAlbumAlert = newValue == .invalid
        }
    }
    @Published var publicLinkDecryptionKey = ""
    @Published var showingDecryptionKeyAlert = false
    @Published var showCannotAccessAlbumAlert = false
    
    let photoLibraryContentViewModel: PhotoLibraryContentViewModel
    private let publicAlbumUseCase: any PublicAlbumUseCaseProtocol
    private var publicLink: URL
    
    init(publicLink: URL,
         publicAlbumUseCase: some PublicAlbumUseCaseProtocol) {
        self.publicLink = publicLink
        self.publicAlbumUseCase = publicAlbumUseCase
        
        photoLibraryContentViewModel = PhotoLibraryContentViewModel(library: PhotoLibrary(),
                                                                    contentMode: .albumLink)
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
              let newURL = URL(string: publicLink.absoluteString + "#" + publicLinkDecryptionKey) else {
            publicLinkStatus = .invalid
            return
        }
        publicLink = newURL
        loadPublicAlbum()
    }
    
    private func loadPublicAlbumContents() {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            do {
                let photos = try await publicAlbumUseCase.publicPhotos(forLink: publicLink.absoluteString)
                try Task.checkCancellation()
                photoLibraryContentViewModel.library = photos.toPhotoLibrary(withSortType: .newest)
                publicLinkStatus = .loaded
            } catch let error as SharedAlbumErrorEntity {
                publicLinkStatus = .invalid
                MEGALogError("Error retrieving public album: \(error.localizedDescription)")
            } catch {
                MEGALogError("Error retrieving public album: \(error.localizedDescription)")
            }
        }
    }
    
    private func decryptionKeyRequired() -> Bool {
        publicLink.absoluteString.components(separatedBy: "#").count == 1
    }
}
