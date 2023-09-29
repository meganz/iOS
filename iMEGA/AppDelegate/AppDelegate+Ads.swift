import Accounts
import MEGADomain
import MEGASDKRepo
import SwiftUI

extension AppDelegate {
    @objc func isAdsMainTabBarRootView() -> Bool {
        window.isKind(of: UIHostingController<AdsSlotView<MainTabBarWrapper>>.self)
    }

    @objc func adsMainTabBarController(_ tabBar: MainTabBarController) -> UIViewController {
        AdsSlotRouter(
            adsSlotViewController: tabBar,
            contentView: MainTabBarWrapper(mainTabBar: tabBar)
        ).build()
    }
}
