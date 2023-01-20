import SwiftUI
import MEGADomain

struct AlbumContainerWrapper: UIViewControllerRepresentable {
    private let album: AlbumEntity
    private let messageForNewAlbum: String?
    
    init(album: AlbumEntity, messageForNewAlbum: String?) {
        self.album = album
        self.messageForNewAlbum = messageForNewAlbum
    }
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let nav = MEGANavigationController(rootViewController: AlbumContentRouter(album: album, messageForNewAlbum: messageForNewAlbum).build())
        nav.modalPresentationStyle = .fullScreen
        
        return nav
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}
