import Accounts
import Combine
import MEGADomain

extension MainTabBarController: AdsSlotViewControllerProtocol {
    public var adsSlotPublisher: AnyPublisher<AdsSlotConfig?, Never> {
        mainTabBarAdsViewModel.adsSlotConfigPublisher
    }
    
    @objc func configureAdsVisibility() {
        mainTabBarAdsViewModel.sendNewAdsConfig(currentAdsSlotConfig())
    }
    
    private func currentAdsSlotConfig() -> AdsSlotConfig? {
        switch selectedIndex {
        case TabType.cloudDrive.rawValue:
            guard let cloudDriveViewController = mainTabBarTopViewController() as? CloudDriveViewController else {
                return AdsSlotConfig(
                    adsSlot: .files,
                    displayAds: false
                )
            }
            
            return AdsSlotConfig(
                adsSlot: .files,
                displayAds: cloudDriveViewController.displayMode == .cloudDrive
            )
            
        case TabType.cameraUploads.rawValue:
            return AdsSlotConfig(
                adsSlot: .photos,
                displayAds: isVisibleController(type: PhotoAlbumContainerViewController.self)
            )
            
        case TabType.home.rawValue:
            return AdsSlotConfig(
                adsSlot: .home,
                displayAds: isVisibleController(type: HomeViewController.self)
            )
            
        case TabType.chat.rawValue, TabType.sharedItems.rawValue:
            return nil
            
        default:
            return nil
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
