
import Foundation

extension UIApplication {
    @objc class func openAppleIDSubscriptionsPage() {
        guard let url = URL(string: "https://apps.apple.com/account/subscriptions") else { return }
        self.shared.open(url, options: [:], completionHandler: nil)
    }
    
    @objc class func openAppStoreSettings() {
        guard let url = URL(string: "itms-ui://") else { return }
        self.shared.open(url, options: [:], completionHandler: nil)
    }
}
