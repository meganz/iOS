import SwiftUI
import MEGADomain

struct AlbumContainerWrapper: UIViewControllerRepresentable {
    private let album: AlbumEntity
    
    init(album: AlbumEntity) {
        self.album = album
    }
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let nav = MEGANavigationController(rootViewController: AlbumContentRouter(album: album).build())
        nav.modalPresentationStyle = .fullScreen
        
        return nav
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}
