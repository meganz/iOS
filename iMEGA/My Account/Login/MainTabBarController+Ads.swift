import Accounts
import MEGADomain
import MEGASDKRepo
import MEGASwift

extension MainTabBarController: AdsSlotViewControllerProtocol {
    public var adsSlotUpdates: AnyAsyncSequence<AdsSlotConfig?> {
        mainTabBarAdsViewModel.adsSlotConfigAsyncSequence
    }
    
    @objc func configureAdsVisibility() {
        mainTabBarAdsViewModel.sendNewAdsConfig(currentAdsSlotConfig())
    }
    
    private func currentAdsSlotConfig() -> AdsSlotConfig? {
        switch selectedIndex {
        case TabType.cloudDrive.rawValue:
            let displayAds = if let adsDisplayable = mainTabBarTopViewController() as? any CloudDriveAdsSlotDisplayable {
                adsDisplayable.shouldDisplayAdsSlot
            } else {
                false
            }
            
            return AdsSlotConfig(
                adsSlot: .files,
                displayAds: displayAds
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
    
    private func calculateAdCookieStatus() async -> Bool {
        do {
            let cookieSettingsUseCase = CookieSettingsUseCase(repository: CookieSettingsRepository.newRepo)
            let bitmap = try await cookieSettingsUseCase.cookieSettings()
            
            let cookiesBitmap = CookiesBitmap(rawValue: bitmap)
            return cookiesBitmap.contains(.ads) && cookiesBitmap.contains(.adsCheckCookie)
        } catch {
            return false
        }
    }
}
