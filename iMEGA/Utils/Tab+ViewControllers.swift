import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAPreference

@MainActor
extension Tab {
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
            case .menu:
                return AccountMenuViewRouter().build()
            default:
                assertionFailure("Could not create view controller for tab: \(self.title)")
                return nil
            }
        }()

        viewController?.tabBarItem.title = title
        viewController?.tabBarItem.image = icon
        viewController?.tabBarItem.selectedImage = selectedIcon
        return viewController
    }
}
