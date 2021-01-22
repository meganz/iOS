
protocol PSAViewRouting: PSAViewDelegate, Routing {
    func psaView() -> PSAView?
    func isPSAViewAlreadyShown() -> Bool
    func adjustPSAViewFrame()
    func hidePSAView(_ hide: Bool)
}

@objc
final class PSAViewRouter: NSObject, PSAViewRouting {
    
    private weak var tabBarController: UITabBarController?
    private weak var psaViewBottomConstraint: NSLayoutConstraint?
    
    @objc init(tabBarController: UITabBarController) {
        self.tabBarController = tabBarController
    }
    
    func start() {
        guard let tabBarController = tabBarController, isPSAViewAlreadyShown() == false else { return }
        
        let psaView = PSAView.instanceFromNib
        psaView.delegate = self
        psaView.isHidden = true
        tabBarController.view.addSubview(psaView)
        
        psaView.translatesAutoresizingMaskIntoConstraints = false
        psaView.leadingAnchor.constraint(equalTo: tabBarController.view.leadingAnchor).isActive = true
        psaView.trailingAnchor.constraint(equalTo: tabBarController.view.trailingAnchor).isActive = true
        self.psaViewBottomConstraint = psaView.bottomAnchor.constraint(equalTo: tabBarController.view.bottomAnchor, constant: -tabBarController.tabBar.bounds.height)
        self.psaViewBottomConstraint?.isActive = true
        
        self.hidePSAView(false)
    }

    func build() -> UIViewController {
        fatalError("PSA uses view instead of view controller")
    }

    func psaView() -> PSAView? {
        return tabBarController?.view.subviews.filter { $0 is PSAView }.first as? PSAView
    }
    
    func isPSAViewAlreadyShown() -> Bool {
        return psaView() != nil
    }
    
    func adjustPSAViewFrame() {
        guard let bottomConstraint = psaViewBottomConstraint,
              let tabBar = tabBarController?.tabBar,
              bottomConstraint.constant != -tabBar.bounds.height else {
            return
        }
        
        psaViewBottomConstraint?.constant = -tabBar.bounds.height
        psaView()?.layoutIfNeeded()
    }
    
    func hidePSAView(_ hide: Bool) {
        guard let psaView = psaView(), psaView.isHidden != hide else { return }
        
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
        NSURL(string: urlString)?.mnz_presentSafariViewController()
    }
    
    func dismiss(psaView: PSAView) {
        psaView.removeFromSuperview()
    }
}
