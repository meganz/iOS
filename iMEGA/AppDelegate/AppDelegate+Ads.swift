import MEGADomain
import MEGASDKRepo
import SwiftUI

extension AppDelegate {
    @objc func isAdsMainTabBarRootView() -> Bool {
        window.isKind(of: UIHostingController<AdsSlotView<MainTabBarWrapper>>.self)
    }

    @objc func adsMainTabBarController(_ tabBar: MainTabBarController) -> UIViewController {
        let viewModel = AdsSlotViewModel(adsUseCase: AdsUseCase(repository: AdsRepository.newRepo),
                                         accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
                                         adsSlotChangeStream: AdsSlotChangeStream(adsSlotViewController: tabBar))
        let adsSlotView = AdsSlotView(viewModel: viewModel,
                                      contentView: MainTabBarWrapper(mainTabBar: tabBar))
        return UIHostingController(rootView: adsSlotView)
    }
}
