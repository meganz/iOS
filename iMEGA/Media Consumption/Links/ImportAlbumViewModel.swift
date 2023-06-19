import SwiftUI
import Combine
import MEGADomain
import MEGASwift

final class ImportAlbumViewModel: ObservableObject {
    @Published var publicLink: URL
    @Published var publicLinkStatus: AlbumPublicLinkStatus = .none {
        willSet {
            showingDecryptionKeyAlert = newValue == .requireDecryptionKey
        }
    }
    @Published var publicLinkDecryptionKey = ""
    @Published var showingDecryptionKeyAlert = false
    
    private let shareAlbumUseCase: any ShareAlbumUseCaseProtocol
    
    init(shareAlbumUseCase: any ShareAlbumUseCaseProtocol,
         publicLink: URL) {
        self.shareAlbumUseCase = shareAlbumUseCase
        self.publicLink = publicLink
        
        checkPublicLink()
    }
    
    func checkPublicLink() {
        publicLinkStatus = .inProgress
        if decryptionKeyRequired() {
            publicLinkStatus = .requireDecryptionKey
        } else {
            publicLinkStatus = .none
        }
    }
    
    private func decryptionKeyRequired() -> Bool {
        publicLink.absoluteString.components(separatedBy: "#").count == 1
    }
}
