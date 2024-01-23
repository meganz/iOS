import Accounts
import MEGADomain
import MEGASDKRepo
import SwiftUI

extension AppDelegate {
    @objc func isAdsMainTabBarRootView() -> Bool {
        window.rootViewController?.isKind(of: UIHostingController<AdsSlotView<MainTabBarWrapper>>.self) ?? false
    }

    @objc func adsMainTabBarController(_ tabBar: MainTabBarController, onAppear: (() -> Void)?) -> UIViewController {
        AdsSlotRouter(
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
            adsSlotViewController: tabBar,
            contentView: MainTabBarWrapper(mainTabBar: tabBar)
        ).build(onViewAppeared: onAppear)
    }
}
