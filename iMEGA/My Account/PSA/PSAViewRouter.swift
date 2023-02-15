import MEGAPresentation

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
    private weak var psaViewBottomConstraint: NSLayoutConstraint?
    
    @objc init(tabBarController: UITabBarController) {
        self.tabBarController = tabBarController
    }
    
    func start() {
        guard let tabBarController = tabBarController else { return }
        
        let psaView = PSAView.instanceFromNib
        psaView.isHidden = true
        tabBarController.view.addSubview(psaView)
        
        psaView.translatesAutoresizingMaskIntoConstraints = false
        psaView.leadingAnchor.constraint(equalTo: tabBarController.view.leadingAnchor).isActive = true
        psaView.trailingAnchor.constraint(equalTo: tabBarController.view.trailingAnchor).isActive = true
        psaView.bottomAnchor.constraint(equalTo: tabBarController.tabBar.topAnchor).isActive = true
        
        self.hidePSAView(false)
    }

    func build() -> UIViewController {
        fatalError("PSA uses view instead of view controller")
    }

    func currentPSAView() -> PSAView? {
        return tabBarController?.view.subviews.first { $0 is PSAView } as? PSAView
    }
    
    func isPSAViewAlreadyShown() -> Bool {
        return currentPSAView() != nil
    }
    
    func hidePSAView(_ hide: Bool) {
        guard let psaView = currentPSAView(), psaView.isHidden != hide else { return }
        
        if !hide {
            psaView.alpha = 0.0
        }
        
        UIView.animate(withDuration: 0.4) {
            psaView.alpha = hide ? 0.0 : 1.0
        } completion: { _ in
            psaView.isHidden = hide
            if hide {
                psaView.alpha = 1.0
            }
        }
    }

    // MARK:- PSAViewDelegate
    
    func openPSAURLString(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            MEGALogDebug("The url \(urlString) could not be opened")
            return
        }
        
        MEGALinkManager.linkURL = url
        MEGALinkManager.processLinkURL(url)
    }
    
    func dismiss(psaView: PSAView) {
        psaView.removeFromSuperview()
    }
}
