import Accounts
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADesignToken
import MEGADomain
import MEGAInfrastructure
import MEGAPreference
import MEGARepo
import MEGASwiftUI
import SwiftUI

@MainActor
public protocol AccountMenuItemsNavigating {
    func showSharedItems()
    func showAchievements()
}

final class AccountMenuViewNavigationController: MEGANavigationController, AccountMenuItemsNavigating {
    private let viewModel = AccountMenuNotificationsViewModel(
        accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
        sharedItemsUseCase: ShareUseCase(
            shareRepository: ShareRepository.newRepo,
            filesSearchRepository: FilesSearchRepository.newRepo,
            nodeRepository: NodeRepository.newRepo),
        notificationsUseCase: NotificationsUseCase(repository: NotificationsRepository.newRepo),
        contactsUseCase: ContactsUseCase(repository: ContactsRepository.newRepo)
    )

    var router: (any AccountMenuViewRouting)?
    private var notificationObservingTask: Task<Void, Never>?

    init() {
        super.init(nibName: nil, bundle: nil)
        onInit()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showAchievements() {
        router?.showAchievements()
    }

    func showSharedItems() {
        router?.showSharedItems()
    }

    private func onInit() {
        notificationObservingTask = Task { [viewModel] in
            for await value in viewModel.notificationBadgeValue {
                tabBarItem.badgeValue = value
            }
        }
    }

    deinit {
        // Here we cancel notificationObservingTask in deinit instead of will/didDisappear because
        // Account Menu is one of the app's tab bar view controller, the task should always be active
        // until the VC is deallocated (e.g: user logs out).
        notificationObservingTask?.cancel()
    }
}

@MainActor
struct AccountMenuViewRouter: AccountMenuViewRouting {
    let navigationController = AccountMenuViewNavigationController()

    func build() -> UIViewController {
        let userImageUseCase = UserImageUseCase(
            userImageRepo: UserImageRepository.newRepo,
            userStoreRepo: UserStoreRepository(store: MEGAStore.shareInstance()),
            thumbnailRepo: ThumbnailRepository.newRepo,
            fileSystemRepo: FileSystemRepository.sharedRepo
        )
        let megaHandleUseCase = MEGAHandleUseCase(repo: MEGAHandleRepository.newRepo)
        let viewModel = AccountMenuViewModel(
            router: self,
            currentUserSource: .shared,
            tracker: DIContainer.tracker,
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
            userImageUseCase: userImageUseCase,
            megaHandleUseCase: megaHandleUseCase,
            networkMonitorUseCase: NetworkMonitorUseCase(repo: NetworkMonitorRepository.newRepo),
            preferenceUseCase: PreferenceUseCase.default,
            notificationsUseCase: NotificationsUseCase(repository: NotificationsRepository.newRepo),
            purchaseUseCase: AccountPlanPurchaseUseCase(repository: AccountPlanPurchaseRepository.newRepo),
            fullNameHandler: { currentUserSource in
                currentUserSource.currentUser?.mnz_fullName ?? ""
            },
            avatarFetchHandler: { fullName, handle in
                guard let base64Handle = megaHandleUseCase.base64Handle(forUserHandle: handle) else {
                    MEGALogError("base64 handle not found for handle \(handle)")
                    return nil
                }

                let backgroundColor = userImageUseCase.avatarColorHex(forBase64UserHandle: base64Handle)

                let avatarHandler = UserAvatarHandler(
                    userImageUseCase: userImageUseCase,
                    initials: fullName.initialForAvatar(),
                    avatarBackgroundColor: UIColor.colorFromHexString(backgroundColor) ?? TokenColors.Icon.primary
                )

                return await avatarHandler.avatar(for: base64Handle)
            },
            logoutHandler: logout,
            sharedItemsNotificationCountHandler: sharedItemsNotificationCountHandler
        )

        let hostingViewController = UIHostingController(
            rootView: AccountMenuView(viewModel: viewModel)
        )

        hostingViewController.navigationItem.backButtonTitle = ""

        navigationController.viewControllers = [hostingViewController]
        navigationController.router = self

        return navigationController
    }

    func showNotifications() {
        NotificationsViewRouter(
            navigationController: navigationController,
            notificationsUseCase: NotificationsUseCase(repository: NotificationsRepository.newRepo),
            nodeUseCase: NodeUseCase(
                nodeDataRepository: NodeDataRepository.newRepo,
                nodeValidationRepository: NodeValidationRepository.newRepo,
                nodeRepository: NodeRepository.newRepo
            ),
            imageLoader: ImageLoader(),
            hidesBottomBarWhenPushed: true
        ).start()
    }

    func showAccount() {
        ProfileViewRouter(
            navigationController: navigationController,
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo)
        ).start()
    }

    func upgradeAccount() {
        let accountUseCase = AccountUseCase(repository: AccountRepository.newRepo)
        guard let accountDetails = accountUseCase.currentAccountDetails else {
            MEGALogDebug("The account details is nil - cannot upgrade")
            return
        }
        
        SubscriptionPurchaseRouter(
            presenter: UIApplication.mnz_presentingViewController(),
            currentAccountDetails: accountDetails,
            viewType: .upgrade,
            accountUseCase: accountUseCase
        ).start()
    }

    func showStorage() {
        UsageViewRouter(
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
            accountStorageUseCase: AccountStorageUseCase(
                accountRepository: AccountRepository.newRepo,
                preferenceUseCase: PreferenceUseCase.default
            ),
            navigationController: navigationController,
            hidesBottomBarWhenPushed: true
        ).start()
    }

    func showContacts() {
        let contactsVC = UIStoryboard(name: "Contacts", bundle: nil)
            .instantiateViewController(withIdentifier: "ContactsViewControllerID")
        navigationController.pushViewController(contactsVC, animated: true)
    }

    func showAchievements() {
        let achievementsVC = UIStoryboard(name: "Achievements", bundle: nil)
            .instantiateViewController(withIdentifier: "AchievementsViewControllerID")
        navigationController.pushViewController(achievementsVC, animated: true)
    }

    func showSharedItems() {
        guard let sharedItemsNavigationController = UIStoryboard(name: "SharedItems", bundle: nil)
            .instantiateInitialViewController() as? MEGANavigationController,
              let vc = sharedItemsNavigationController.viewControllers.first
        else {
            return
        }

        vc.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(vc, animated: true)
    }

    func showTransfers() {
        let transferVC = UIStoryboard(name: "Transfers", bundle: nil)
            .instantiateViewController(withIdentifier: "TransfersWidgetViewControllerID")
        transferVC.navigationItem.leftBarButtonItem = nil
        CrashlyticsLogger.log(category: .transfersWidget, "Showing transfers widget from MyAccountHall")
        navigationController.pushViewController(transferVC, animated: true)
    }

    func showOfflineFiles() {
        let offlineVC = UIStoryboard(name: "Offline", bundle: nil)
            .instantiateViewController(withIdentifier: "OfflineViewControllerID")
        offlineVC.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(offlineVC, animated: true)
    }

    func showRubbishBin() {
        guard let rubbishNode = MEGASdk.shared.rubbishNode else { return }

        let factory = CloudDriveViewControllerFactory.make(nc: navigationController)
        let cloudDriveVC = factory.buildBare(
            parentNode: rubbishNode.toNodeEntity(),
            config: .init(displayMode: .rubbishBin)
        )
        if let cloudDriveVC {
            cloudDriveVC.hidesBottomBarWhenPushed = true
            navigationController.pushViewController(cloudDriveVC, animated: true)
        }
    }

    func showSettings() {
        SettingViewRouter(presenter: navigationController).start()
    }

    func openLink(for app: MegaCompanionApp) {
        guard let url = URL(string: app.link) else {
            assertionFailure("External link for the app \(app) is not valid")
            return
        }

        Task { @MainActor in
            let externalLinkOpener = MEGAInfrastructure.DependencyInjection.externalLinkOpener
            if await externalLinkOpener.canOpenLink(with: url) {
                externalLinkOpener.openExternalLink(with: url)
            }
        }
    }

    private func logout() async {
        let transferUseCase = TransferUseCase(
            repo: TransferRepository.newRepo,
            metadataUseCase: MetadataUseCase(
                metadataRepository: MetadataRepository(),
                fileSystemRepository: FileSystemRepository.sharedRepo,
                fileExtensionRepository: FileExtensionRepository(),
                nodeCoordinatesRepository: NodeCoordinatesRepository.newRepo
            ),
            nodeDataRepository: NodeDataRepository.newRepo
        )

        let transferInventoryUseCaseHelper = TransferInventoryUseCaseHelper()

        do {
            try await transferUseCase.cancelDownloadTransfers()
            try await transferUseCase.cancelUploadTransfers()

            transferInventoryUseCaseHelper.removeAllUploadTransfers()
        } catch {
            MEGALogError("[CancelTransfers] Failed to cancel transfers: \(error)")
        }

        guard let showPasswordReminderDelegate = MEGAShowPasswordReminderRequestDelegate(toLogout: true) else {
            return
        }

        MEGASdk.shared.shouldShowPasswordReminderDialog(atLogout: true, delegate: showPasswordReminderDelegate)
    }

    private func sharedItemsNotificationCountHandler() -> Int {
        let unverifiedInShares = MEGASdk.shared.getUnverifiedInShares(.defaultAsc)
        let unverifiedOutShares = MEGASdk.shared.isContactVerificationWarningEnabled ? MEGASdk.shared.outShares(.defaultAsc)
            .toShareEntities()
            .filter { share in
                share.sharedUserEmail != nil && !share.isVerified
            } : nil

        return unverifiedInShares.size + (unverifiedOutShares?.count ?? 0)
    }
}
