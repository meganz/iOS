import MEGADomain
import MEGASDKRepo
import SwiftUI

extension AppDelegate {
    @objc func isAdsMainTabBarRootView() -> Bool {
        window.rootViewController?.isKind(of: UIHostingController<AdsSlotView<MainTabBarWrapper>>.self) ?? false
    }

    @objc func adsMainTabBarController(_ tabBar: MainTabBarController) -> UIViewController {
        let viewModel = AdsSlotViewModel(adsUseCase: AdsUseCase(repository: AdsRepository.newRepo),
                                         adsSlotChangeStream: AdsSlotChangeStream(adsSlotViewController: tabBar))
        let adsSlotView = AdsSlotView(viewModel: viewModel,
                                      contentView: MainTabBarWrapper(mainTabBar: tabBar))
        return UIHostingController(rootView: adsSlotView)
    }
}
