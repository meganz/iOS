import CoreGraphics
import MEGAL10n

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
    
    @objc func openApp() {
        if self.openAppNC == nil {
            self.openAppNC = UIStoryboard(name: "Share", bundle: Bundle(for: OpenAppRequiredViewController.self)).instantiateViewController(withIdentifier: "OpenAppRequiredNavigationViewController") as? UINavigationController
            let openAppVC = self.openAppNC?.children.first as? OpenAppRequiredViewController
            openAppVC?.navigationItem.title = "MEGA"
            openAppVC?.cancelBarButtonItem.title = Strings.Localizable.cancel
            
            openAppVC?.cancelCompletion = { [weak self] in
                self?.openAppNC?.dismiss(animated: true) {
                    self?.hideView {
                        MainActor.assumeIsolated {
                            self?.extensionContext?.completeRequest(returningItems: [])
                        }
                    }
                }
            }
            addOpenAppView()
        }
    }
}
