import UIKit

@available(iOS 14.0, *)
struct AlbumContentRouter: Routing {
    private let cameraUploadNode: NodeEntity
    
    init(cameraUploadNode: NodeEntity) {
        self.cameraUploadNode = cameraUploadNode
    }
    
    func build() -> UIViewController {
        let repository = FavouriteNodesRepository(sdk: MEGASdkManager.sharedMEGASdk())
        let favouritesUseCase = FavouriteNodesUseCase(repo: repository)
        let viewModel = AlbumContentViewModel(cameraUploadNode: cameraUploadNode,
                                              albumName: Strings.Localizable.CameraUploads.Albums.Favourites.title,
                                              favouritesUseCase: favouritesUseCase,
                                              router: self)
        let vc = AlbumContentViewController(viewModel: viewModel)
        
        return vc
    }
    
    func start() {}
}
