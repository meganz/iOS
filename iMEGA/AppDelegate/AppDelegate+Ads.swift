import Accounts
import MEGADomain
import MEGAPresentation
import MEGASDKRepo
import SwiftUI

extension AppDelegate {
    @objc func isAdsMainTabBarRootView() -> Bool {
        window.rootViewController?.isKind(of: UIHostingController<AdsSlotView<MainTabBarWrapper>>.self) ?? false
    }

    @objc func adsMainTabBarController(_ tabBar: MainTabBarController, onViewFirstAppeared: (() -> Void)?) -> UIViewController {
        AdsSlotRouter(
            adsSlotViewController: tabBar,
            contentView: MainTabBarWrapper(mainTabBar: tabBar)
        ).build(onViewFirstAppeared: onViewFirstAppeared)
    }
    
    func showAdMobConsentIfNeeded(isFromCookieDialog: Bool = false) async {
        guard await DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .externalAds) else { return }
        do {
            try await GoogleMobileAdsConsentManager.shared.gatherConsent()
            await GoogleMobileAdsConsentManager.shared.initializeGoogleMobileAdsSDK()
        } catch {
            MEGALogError("[AdMob] Google Ads consent manager \(isFromCookieDialog ? "with": "without") cookie dialog received error: \(error)")
        }
    }
}
