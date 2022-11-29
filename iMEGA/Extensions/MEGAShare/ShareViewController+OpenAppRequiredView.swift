import CoreGraphics
extension ShareViewController {
    @objc func addOpenAppView() {
        guard let openAppNC else {
            return
        }
        
        if openAppNC.parent == self {
            return
        }
        
        addChild(openAppNC)
        openAppNC.view.frame = CGRect(x: 0.0, y: 0.0, width: view.frame.size.width, height: view.frame.size.height)
        view.addSubview(openAppNC.view)
    }
    
    @objc func removeOpenAppView() {
        guard let openAppNC else {
            return
        }
        
        openAppNC.removeFromParent()
        openAppNC.view.removeFromSuperview()
    }
    
    @objc func openApp(loginRequired: Bool) {
        if (self.openAppNC == nil) {
            self.openAppNC = UIStoryboard(name: "Share", bundle: Bundle(for: OpenAppRequiredViewController.self)).instantiateViewController(withIdentifier: "OpenAppRequiredNavigationViewController") as? UINavigationController
            let openAppVC = self.openAppNC?.children.first as? OpenAppRequiredViewController
            openAppVC?.isLoginRequired = loginRequired
            openAppVC?.navigationItem.title = "MEGA"
            openAppVC?.cancelBarButtonItem.title = Strings.Localizable.cancel
            
            openAppVC?.cancelCompletion = { [weak self] in
                self?.openAppNC?.dismiss(animated: true) {
                    self?.hideView {
                        self?.extensionContext?.completeRequest(returningItems: [])
                    }
                }
            }
            addOpenAppView()
        }
    }
}
