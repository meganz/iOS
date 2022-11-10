import SwiftUI
import MEGADomain

@available(iOS 14.0, *)
struct AlbumContainerWrapper: UIViewControllerRepresentable {
    var albumNode: NodeEntity?
    var album: AlbumEntity?
    
    init(albumNode: NodeEntity?, album: AlbumEntity?) {
        self.albumNode = albumNode
        self.album = album
    }
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let nav = MEGANavigationController(rootViewController: AlbumContentRouter(cameraUploadNode: albumNode, album: album).build())
        nav.modalPresentationStyle = .fullScreen
        
        return nav
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}
