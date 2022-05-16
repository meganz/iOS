import UIKit

@available(iOS 14.0, *)
struct AlbumContentRouter: Routing {
    private let parentNode: NodeEntity
    
    init(parentNode: NodeEntity) {
        self.parentNode = parentNode
    }
    
    func build() -> UIViewController {
        let repository = FavouriteNodesRepository(sdk: MEGASdkManager.sharedMEGASdk())
        let favouritesUseCase = FavouriteNodesUseCase(repo: repository)
        let viewModel = AlbumContentViewModel(parentNode: parentNode,
                                              albumName: Strings.Localizable.CameraUploads.Albums.Favourites.title,
                                              favouritesUseCase: favouritesUseCase,
                                              router: self)
        let vc = AlbumContentViewController(viewModel: viewModel)
        
        return vc
    }
    
    func start() {}
}
