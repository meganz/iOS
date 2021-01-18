
@objc
protocol PSAViewRouterDelegate: AnyObject {
    func psaViewdismissed()
}

@objc
final class PSAViewRouter: NSObject {
    
    private weak var tabBarController: UITabBarController?
    private weak var psaView: PSAView?
    private weak var psaViewBottomConstraint: NSLayoutConstraint?
    private weak var delegate: PSAViewRouterDelegate?
    
    @objc init(tabBarController: UITabBarController, delegate: PSAViewRouterDelegate) {
        self.tabBarController = tabBarController
        self.delegate = delegate
    }
    
    @objc func start(completion: @escaping ((Bool) -> Void)) {
        guard let tabBarController = tabBarController else { return }

        let useCase = PSAUseCase(repo: PSARepository(sdk: MEGASdkManager.sharedMEGASdk()))
        let viewModel = PSAViewModel(router: self, useCase: useCase)
        
        viewModel.shouldShowView { [weak self] show in
            guard let self = self else { return }
            if show {
                let psaView = PSAView.instanceFromNib
                psaView.viewModel = viewModel
                psaView.delegate = self
                psaView.isHidden = true
                tabBarController.view.addSubview(psaView)
                
                psaView.autoPinEdge(toSuperviewEdge: .leading)
                psaView.autoPinEdge(toSuperviewEdge: .trailing)
                self.psaViewBottomConstraint = psaView.autoPinEdge(.bottom, to: .bottom, of: tabBarController.view, withOffset: -tabBarController.tabBar.bounds.height)
                self.psaView = psaView
                
                self.hidePSAView(false)
            }
            completion(show)
        }
    }
    
    @objc func adjustPSAViewFrame() {
        guard let bottomConstraint = psaViewBottomConstraint,
              let tabBar = tabBarController?.tabBar,
              bottomConstraint.constant != -tabBar.bounds.height else {
            return
        }
        
        psaViewBottomConstraint?.constant = -tabBar.bounds.height
        psaView?.layoutIfNeeded()
    }
    
    @objc func hidePSAView(_ hide: Bool) {
        guard let psaView = psaView, psaView.isHidden != hide else { return }
        
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
}

extension PSAViewRouter: PSAViewDelegate {
    func openPSAURLString(_ urlString: String) {
        NSURL(string: urlString)?.mnz_presentSafariViewController()
    }
    
    func dismiss(psaView: PSAView) {
        psaView.removeFromSuperview()
        delegate?.psaViewdismissed()
    }
}
