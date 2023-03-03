import SwiftUI
import MEGADomain

struct AlbumContainerWrapper: UIViewControllerRepresentable {
    private let album: AlbumEntity
    private let newAlbumPhotos: [NodeEntity]?
    private let existingAlbumNames: () -> [String]
    
    init(album: AlbumEntity, newAlbumPhotos: [NodeEntity]?, existingAlbumNames: @escaping () -> [String]) {
        self.album = album
        self.newAlbumPhotos = newAlbumPhotos
        self.existingAlbumNames = existingAlbumNames
    }
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let navigationController = MEGANavigationController()
        let router = AlbumContentRouter(navigationController: navigationController, album: album, newAlbumPhotos: newAlbumPhotos, existingAlbumNames: existingAlbumNames)
        navigationController.setViewControllers([router.build()], animated: false)
        navigationController.modalPresentationStyle = .fullScreen
        return navigationController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}
