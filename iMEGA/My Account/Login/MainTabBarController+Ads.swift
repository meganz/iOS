import Accounts
import MEGADomain
import MEGAPresentation
import MEGASDKRepo
import MEGASwift

extension MainTabBarController: AdsSlotViewControllerProtocol {
    public var adsSlotUpdates: AnyAsyncSequence<AdsSlotConfig?> {
        mainTabBarAdsViewModel.adsSlotConfigAsyncSequence
    }
    
    func hideAds() {
        guard DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .externalAds) else { return }
        let adsSlot: [Int: AdsSlotEntity] = [
            TabType.cloudDrive.rawValue: .files,
            TabType.cameraUploads.rawValue: .photos,
            TabType.home.rawValue: .home,
            TabType.chat.rawValue: .chat,
            TabType.sharedItems.rawValue: .sharedItems
        ]
        
        guard let currentAdsSlot = adsSlot[selectedIndex] else { return }
        mainTabBarAdsViewModel.sendNewAdsConfig(
            AdsSlotConfig(adsSlot: currentAdsSlot, displayAds: false)
        )
    }
    
    @objc func configureAdsVisibility() {
        mainTabBarAdsViewModel.sendNewAdsConfig(currentAdsSlotConfig())
    }
    
    private func currentAdsSlotConfig() -> AdsSlotConfig? {
        switch selectedIndex {
        case TabType.cloudDrive.rawValue:
            AdsSlotConfig(
                adsSlot: .files,
                displayAds: (mainTabBarTopViewController() as? any CloudDriveAdsSlotDisplayable)?.shouldDisplayAdsSlot ?? false
            )
        case TabType.cameraUploads.rawValue:
            AdsSlotConfig(
                adsSlot: .photos,
                displayAds: isVisibleController(type: PhotoAlbumContainerViewController.self)
            )
            
        case TabType.home.rawValue:
            AdsSlotConfig(
                adsSlot: .home,
                displayAds: isVisibleController(type: HomeViewController.self) ||
                isVisibleController(type: FilesExplorerContainerViewController.self) ||
                isVisibleController(type: VideoRevampTabContainerViewController.self)
            )
            
        case TabType.chat.rawValue:
            AdsSlotConfig(
                adsSlot: .chat,
                displayAds: isVisibleController(type: ChatRoomsListViewController.self)
            )
            
        case TabType.sharedItems.rawValue:
            AdsSlotConfig(
                adsSlot: .sharedItems,
                displayAds: isVisibleController(type: SharedItemsViewController.self) ||
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
