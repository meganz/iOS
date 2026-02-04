import MEGAAppPresentation

typealias PSAPresentableView = any PSAViewType & UIView

protocol PSAViewRouting: Routing {
    func currentPSAView() -> PSAPresentableView?
    func isPSAViewAlreadyShown() -> Bool
    func hidePSAView(_ hide: Bool)
    func openPSAURLString(_ urlString: String)
    func dismiss(psaView: PSAPresentableView)
}

@objc
final class PSAViewRouter: NSObject, PSAViewRouting {
    private weak var tabBarController: UITabBarController?
    
    @objc init(tabBarController: UITabBarController) {
        self.tabBarController = tabBarController
        
        super.init()
    }
    
    func start() {
        guard let tabBar = tabBarController as? MainTabBarController else { return }
        
        let psaView = if #available(iOS 26.0, *), DIContainer.featureFlagProvider.isLiquidGlassEnabled() {
            PSASwiftUIBackedView()
        } else {
            PSAView.instanceFromNib
        }
        
        tabBar.presentPSA(psaView)
    }
    
    func build() -> UIViewController {
        fatalError("PSA uses view instead of view controller")
    }
    
    func currentPSAView() -> PSAPresentableView? {
        (tabBarController as? MainTabBarController)?.currentPSAView()
    }
    
    func isPSAViewAlreadyShown() -> Bool {
        !((tabBarController as? MainTabBarController)?.isPSABannerHidden() ?? true)
    }
    
    func hidePSAView(_ hide: Bool) {
        guard let tabBarController = tabBarController as? MainTabBarController else { return }

        hide ? tabBarController.hidePSA() : tabBarController.showPSA(shouldAddSafeAreaCoverView: tabBarController.tabBar.isHidden == true)
    }
    
    // MARK: - PSAViewDelegate
    
    func openPSAURLString(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            MEGALogDebug("The url \(urlString) could not be opened")
            return
        }
        
        MEGALinkManager.linkURL = url
        MEGALinkManager.processLinkURL(url)
    }
    
    func dismiss(psaView: PSAPresentableView) {
        (tabBarController as? MainTabBarController)?.dismissPSA()
    }
}
