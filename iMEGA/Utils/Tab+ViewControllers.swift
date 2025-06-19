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
        let viewController = switch tabType {
        case .home:
            mainTabBarController.makeHomeViewController()
        case .cloudDrive:
            mainTabBarController.makeCloudDriveViewController()
        case .cameraUploads:
            mainTabBarController.photoAlbumViewController()
        case .chat:
            mainTabBarController.chatViewController()
        case .sharedItems:
            mainTabBarController.sharedItemsViewController()
        case .menu:
            menuViewController()
        }

        viewController?.tabBarItem.title = displayTitle
        viewController?.tabBarItem.image = icon
        return viewController
    }

    private func menuViewController() -> UIViewController {
        let navigation = MEGANavigationController()

        let router = MyAccountHallRouter(
            myAccountHallUseCase: MyAccountHallUseCase(repository: AccountRepository.newRepo),
            purchaseUseCase: AccountPlanPurchaseUseCase(repository: AccountPlanPurchaseRepository.newRepo),
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
            accountStorageUseCase: AccountStorageUseCase(
                accountRepository: AccountRepository.newRepo,
                preferenceUseCase: PreferenceUseCase.default
            ),
            shareUseCase: ShareUseCase(
                shareRepository: ShareRepository.newRepo,
                filesSearchRepository: FilesSearchRepository.newRepo,
                nodeRepository: NodeRepository.newRepo),
            networkMonitorUseCase: NetworkMonitorUseCase(repo: NetworkMonitorRepository.newRepo),
            notificationsUseCase: NotificationsUseCase(repository: NotificationsRepository.newRepo),
            navigationController: navigation
        )
        return router.build()
    }
}
