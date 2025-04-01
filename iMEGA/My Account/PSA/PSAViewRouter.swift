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
    private weak var psaViewBottomConstraint: NSLayoutConstraint?
    private var tabBarObservation: NSKeyValueObservation?
    
    @objc init(tabBarController: UITabBarController) {
        self.tabBarController = tabBarController
        
        super.init()
        
        tabBarObservation = tabBarController.tabBar.observe(\.frame, options: [.new]) { [weak self] _, change in
            guard let self = self,
                  let newHeight = change.newValue?.height,
                  let bottomConstraint = self.psaViewBottomConstraint,
                  let psaView = self.currentPSAView(),
                  abs(bottomConstraint.constant) != newHeight else {
                return
            }
            
            bottomConstraint.constant = -newHeight
            psaView.layoutIfNeeded()
        }
    }
    
    deinit {
        tabBarObservation?.invalidate()
    }
    
    func start() {
        guard let tabBarController = tabBarController else { return }
        
        let psaView = PSAView.instanceFromNib
        psaView.isHidden = true
        tabBarController.view.addSubview(psaView)
        
        psaView.translatesAutoresizingMaskIntoConstraints = false
        psaView.leadingAnchor.constraint(equalTo: tabBarController.view.leadingAnchor).isActive = true
        psaView.trailingAnchor.constraint(equalTo: tabBarController.view.trailingAnchor).isActive = true
        psaViewBottomConstraint = psaView.bottomAnchor.constraint(
            equalTo: tabBarController.view.bottomAnchor,
            constant: -tabBarController.tabBar.bounds.size.height
        )
        psaViewBottomConstraint?.isActive = true
        hidePSAView(false)
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
        psaView.removeFromSuperview()
    }
}
