import Accounts
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGASwift
import SwiftUI

extension MainTabBarController: AdsSlotViewControllerProtocol {
    public var adsSlotUpdates: AnyAsyncSequence<AdsSlotConfig?> {
        mainTabBarAdsViewModel.adsSlotConfigAsyncSequence
    }
    
    func hideAds() {
        guard DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .externalAds) else { return }
        mainTabBarAdsViewModel.sendNewAdsConfig(
            AdsSlotConfig(displayAds: false)
        )
    }
    
    @objc func configureAdsVisibility() {
        mainTabBarAdsViewModel.sendNewAdsConfig(currentAdsSlotConfig())
    }
    
    private func currentAdsSlotConfig() -> AdsSlotConfig? {
        // In Navigation Revamp, SharedItems are not available, thus directly calling TabManager.sharedItemsTabIndex()
        // will cause a assertionFailure() to trigger. Here I work around by combining isNavigationRevampEnabled with selectedIndex
        // in the switch, when isNavigationRevampEnabled is `true`, the switch case will fall through and TabManager.sharedItemsTabIndex()
        // won't be called, hence properly avoided the assertion assertionFailure().
        switch (isNavigationRevampEnabled, selectedIndex) {
        case (_, TabManager.driveTabIndex()):
            AdsSlotConfig(
                displayAds: (mainTabBarTopViewController() as? any CloudDriveAdsSlotDisplayable)?.shouldDisplayAdsSlot ?? false
            )
        case (_, TabManager.photosTabIndex()):
            AdsSlotConfig(
                displayAds: isVisibleController(type: PhotoAlbumContainerViewController.self)
            )
            
        case (_, TabManager.homeTabIndex()):
            AdsSlotConfig(
                displayAds: isVisibleController(type: HomeViewController.self) ||
                isVisibleController(type: FilesExplorerContainerViewController.self) ||
                isVisibleController(type: VideoRevampTabContainerViewController.self)
            )
            
        case (_, TabManager.chatTabIndex()):
            AdsSlotConfig(
                displayAds: isVisibleController(type: ChatRoomsListViewController.self)
            )
            
        case (false, TabManager.sharedItemsTabIndex()):
            AdsSlotConfig(
                displayAds: isVisibleController(type: SharedItemsViewController.self) ||
                isVisibleController(type: NewCloudDriveViewController.self)
            )
        case (true, TabManager.menuTabIndex()):
            AdsSlotConfig(
                displayAds: isVisibleController(type: UIHostingController<AccountMenuView>.self) ||
                isVisibleController(type: NewCloudDriveViewController.self)
            )
        default:
            nil
        }
    }
    
    private func isVisibleController<T: UIViewController>(type viewControllerType: T.Type) -> Bool {
        guard let topViewController = mainTabBarTopViewController() else { return false }
        return topViewController.isKind(of: viewControllerType)
    }
    
    private func mainTabBarTopViewController() -> UIViewController? {
        guard let selectedNavController = selectedViewController as? UINavigationController,
              let topViewController = selectedNavController.topViewController else {
            return nil
        }
        return topViewController
    }
}
