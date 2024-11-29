import MEGADomain
import SwiftUI

struct AlbumContainerWrapper: UIViewControllerRepresentable {
    private let album: AlbumEntity
    private let newAlbumPhotos: [NodeEntity]?
    
    init(album: AlbumEntity, newAlbumPhotos: [NodeEntity]? = nil) {
        self.album = album
        self.newAlbumPhotos = newAlbumPhotos
    }
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let navigationController = MEGANavigationController()
        let router = AlbumContentRouter(navigationController: navigationController, album: album, newAlbumPhotos: newAlbumPhotos)
        navigationController.setViewControllers([router.build()], animated: false)
        navigationController.modalPresentationStyle = .fullScreen
        return navigationController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}
