import MEGAAppPresentation

protocol PSAViewRouting: Routing {
    func currentPSAView() -> PSAView?
    func isPSAViewAlreadyShown() -> Bool
    func hidePSAView(_ hide: Bool)
    func openPSAURLString(_ urlString: String)
    func dismiss(psaView: PSAView)
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
        
        let psaView = PSAView.instanceFromNib
        
        tabBar.presentPSA(psaView)
    }
    
    func build() -> UIViewController {
        fatalError("PSA uses view instead of view controller")
    }
    
    func currentPSAView() -> PSAView? {
        (tabBarController as? MainTabBarController)?.currentPSAView()
    }
    
    func isPSAViewAlreadyShown() -> Bool {
        !((tabBarController as? MainTabBarController)?.isPSABannerHidden() ?? true)
    }
    
    func hidePSAView(_ hide: Bool) {
        guard let tabBar = tabBarController as? MainTabBarController else { return }
        
        hide ? tabBar.hidePSA() : tabBar.showPSA()
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
    
    func dismiss(psaView: PSAView) {
        (tabBarController as? MainTabBarController)?.dismissPSA()
    }
}
