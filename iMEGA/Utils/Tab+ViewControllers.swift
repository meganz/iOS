import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAPreference

@MainActor
extension Tab {

    private var displayTitle: String? {
        DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .navigationRevamp) ? title : nil
    }

    func viewController(from mainTabBarController: MainTabBarController) -> UIViewController? {
        let viewController: UIViewController? = {
            switch self {
            case .home:
                return mainTabBarController.makeHomeViewController()
            case .cloudDrive:
                return mainTabBarController.makeCloudDriveViewController()
            case .cameraUploads:
                return mainTabBarController.photoAlbumViewController()
            case .chat:
                return mainTabBarController.chatViewController()
            case .sharedItems:
                return mainTabBarController.sharedItemsViewController()
            case .menu:
                return AccountMenuViewRouter().build()
            default:
                assertionFailure("Could not create view controller for tab: \(self.title)")
                return nil
            }
        }()

        viewController?.tabBarItem.title = displayTitle
        viewController?.tabBarItem.image = icon
        return viewController
    }
}
