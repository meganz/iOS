import UIKit

@available(iOS 14.0, *)
struct AlbumContentRouter: Routing {
    private let cameraUploadNode: NodeEntity
    
    init(cameraUploadNode: NodeEntity) {
        self.cameraUploadNode = cameraUploadNode
    }
    
    func build() -> UIViewController {
        let sdk = MEGASdkManager.sharedMEGASdk()
        
        let repository = FavouriteNodesRepository(sdk: sdk)
        let nodesUpdateRepo = SDKNodesUpdateListenerRepository(sdk: sdk)
        let albumContentsRepo = AlbumContentsUpdateNotifierRepository(
            sdk: sdk,
            nodesUpdateListenerRepo: nodesUpdateRepo
        )
        let favouritesUseCase = FavouriteNodesUseCase(repo: repository)
        let albumContentsUseCase = AlbumContentsUseCase(
            albumContentsRepo: albumContentsRepo
        )
        
        let viewModel = AlbumContentViewModel(cameraUploadNode: cameraUploadNode,
                                              albumName: Strings.Localizable.CameraUploads.Albums.Favourites.title,
                                              favouritesUseCase: favouritesUseCase,
                                              albumContentsUseCase: albumContentsUseCase,
                                              router: self)
        let vc = AlbumContentViewController(viewModel: viewModel)
        
        return vc
    }
    
    func start() {}
}
