
final class FavouritesRouter: NSObject, Routing {
    private weak var navigationController: UINavigationController?
    private weak var homeViewController: HomeViewController?
    private weak var slidePanelView: SlidePanelView?
    
    init(navigationController: UINavigationController, homeViewController: HomeViewController, slidePanelView: SlidePanelView) {
        self.navigationController = navigationController
        self.homeViewController = homeViewController
        self.slidePanelView = slidePanelView
    }
}

extension FavouritesRouter: FavouritesRouting {
    func build() -> UIViewController {
        let favouritesVC = UIStoryboard(name: "Favourites", bundle: nil)
            .instantiateViewController(withIdentifier: "FavouritesViewControllerID") as! FavouritesViewController
        
        let repository = FavouriteNodesRepository(sdk: MEGASdkManager.sharedMEGASdk())
        let favouritesUseCase = FavouriteNodesUseCase(repo: repository)
        
        let viewModel = FavouritesViewModel(router: self, favouritesUseCase: favouritesUseCase)
        favouritesVC.viewModel = viewModel
        
        return favouritesVC
    }
    
    func start() {
        guard let favouritesVC = build() as? FavouritesViewController else { return }
        homeViewController?.addChild(favouritesVC)
        slidePanelView?.addFavouritesViewController(favouritesVC)
        favouritesVC.didMove(toParent: homeViewController)
    }
    
    func openNode(_ nodeHandle: HandleEntity) {
        let nodeOpener = NodeOpener(navigationController: navigationController)
        nodeOpener.openNode(nodeHandle)
    }
    
    func openNodeActions(nodeHandle: HandleEntity, sender: Any) {
        let nodeOpener = NodeOpener(navigationController: navigationController)
        nodeOpener.openNodeActions(nodeHandle, sender: sender)
    }
}
