import SwiftUI
import MEGADomain

@available(iOS 14.0, *)
struct AlbumContainerWrapper: UIViewControllerRepresentable {
    var albumNode: NodeEntity?
    
    init(albumNode: NodeEntity?) {
        self.albumNode = albumNode
    }
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let nav = MEGANavigationController(rootViewController: AlbumContentRouter(cameraUploadNode: albumNode).build())
        nav.modalPresentationStyle = .fullScreen
        
        return nav
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}
