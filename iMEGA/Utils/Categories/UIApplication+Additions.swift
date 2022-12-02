
import Foundation

extension UIApplication {
    @objc class func openAppleIDSubscriptionsPage() {
        guard let url = URL(string: "https://apps.apple.com/account/subscriptions") else { return }
        self.shared.open(url, options: [:], completionHandler: nil)
    }
    
    @available(iOS 15.0, *)
    @objc class func showManageSubscriptions() {
        guard let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              !ProcessInfo.processInfo.isiOSAppOnMac else {
                  UIApplication.openAppleIDSubscriptionsPage()
                  return
        }
        
        Task {
            do {
                try await AppStore.showManageSubscriptions(in: scene)
            } catch {
                UIApplication.openAppleIDSubscriptionsPage()
            }
        }
    }
    
    @objc class func openAppStoreSettings() {
        guard let url = URL(string: "itms-ui://") else { return }
        self.shared.open(url, options: [:], completionHandler: nil)
    }
    
    var isSplitOrSlideOver: Bool {
        guard let w = self.delegate?.window, let window = w else { return false }
        return !window.frame.equalTo(window.screen.bounds)
    }
    
    var keyWindow: UIWindow? {
        UIApplication.shared.windows.first(where: \.isKeyWindow)
    }
}
