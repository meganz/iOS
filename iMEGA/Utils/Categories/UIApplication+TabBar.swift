import SwiftUI

@objc
extension UIApplication {
    class func mainTabBarRootViewController() -> UITabBarController? {
        guard let rootViewController = UIApplication.mnz_keyWindow()?.rootViewController as? UIHostingController<AdsSlotView<MainTabBarWrapper>> else {
            return nil
        }
        return rootViewController.rootView.contentView.mainTabBar
    }
    
    class func mainTabBarVisibleController() -> UIViewController? {
        guard let rootViewController = UIApplication.mnz_presentingViewController() as? UIHostingController<AdsSlotView<MainTabBarWrapper>> else {
            return nil
        }

        let mainTabBar = rootViewController.rootView.contentView.mainTabBar
        guard let selectedViewController = mainTabBar.selectedViewController else {
            return nil
        }
        
        guard let navigationController = selectedViewController as? UINavigationController else {
            return selectedViewController
        }
        
        return navigationController.viewControllers.last
    }

}
