
final class BannerContainerViewRouter: NSObject {
    private weak var navigationController: UINavigationController?
    private var contentViewController: UIViewController
    private var bannerMessage: String
    private var bannerType: BannerType
    
    @objc init(navigationController: UINavigationController, contentViewController: UIViewController, bannerMessage: String, bannerType: BannerType) {
        self.navigationController = navigationController
        self.contentViewController = contentViewController
        self.bannerMessage = bannerMessage
        self.bannerType = bannerType
    }
    
    @objc init(contentViewController: UIViewController, bannerMessage: String, bannerType: BannerType) {
        self.contentViewController = contentViewController
        self.bannerMessage = bannerMessage
        self.bannerType = bannerType
    }
}

extension BannerContainerViewRouter: BannerContainerViewRouting {
    @objc func build() -> UIViewController {
        let bannerContainerVC = UIStoryboard(name: "BannerContainer", bundle: nil)
            .instantiateViewController(withIdentifier: "BannerContainerID") as! BannerContainerViewController
        
        bannerContainerVC.contentVC = contentViewController
        
        let viewModel = BannerContainerViewModel(router: self, message: bannerMessage, type: bannerType)
        bannerContainerVC.viewModel = viewModel
        
        return bannerContainerVC
    }
    
    @objc func start() {
        navigationController?.pushViewController(build(), animated: true)
    }
}
