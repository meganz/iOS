import Accounts
import ChatRepo
import Home
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAPermissions
import MEGARepo
import SwiftUI
import UIKit

@MainActor
final class HomeViewRouter: HomeViewRouting {
    private weak var navigationController: UINavigationController?
    private let transfersRouter: TransfersRouter
    private let offlineFilesUseCase: any OfflineFilesUseCaseProtocol
    private let legacyHomeRouter: any HomeRouterProtocol
    private let shareLinkRouter: ShareLinkDialogRouter

    init(
        navigationController: UINavigationController,
        offlineFilesUseCase: some OfflineFilesUseCaseProtocol,
        legacyHomeRouter: some HomeRouterProtocol,
    ) {
        self.navigationController = navigationController
        self.transfersRouter = TransfersRouter(navigationController: navigationController)
        self.offlineFilesUseCase = offlineFilesUseCase
        self.legacyHomeRouter = legacyHomeRouter
        self.shareLinkRouter = ShareLinkDialogRouter(presenter: navigationController)
    }

    func route(to type: HomeWidgetRouteType) {
        switch type {
        case .shortcut(let shortcutType):
            route(to: shortcutType)
        case .accountUpgrade:
            showUpgradePlanView()		
        case .promotionalBanner(let url):
            routeToPromotionalUrl(url)
        case .viewedLink(let url):
            openViewedLink(url)
        case .promoLandingDialog:
            showPromoLandingDialog()
        case .offline:
            showOffline()
        case .transfers:
            showTransfers()
        case .cameraUploadsOnboarding:
            showCameraUploadsOnboarding()
        case .cameraUploadsSettings:
            showCameraUploadsSettings()
        case .overDiskQuota:
            AppDelegateRouter().showOverDiskQuota()
        case .album(let album):
            showAlbum(album)
        case .inviteContacts:
            showInviteContacts()
        case .scheduleMeeting:
            showScheduleMeeting()
        }
    }

    func openOfflineFile(base64Handle: String) {
        guard let handle = offlineFilesUseCase.offlineFile(for: base64Handle)?.localPath,
              let offlineVC = UIStoryboard(name: "Offline", bundle: nil)
            .instantiateViewController(withIdentifier: "OfflineViewControllerID") as? OfflineViewController else {
            return
        }
        navigationController?.popToRootViewController(animated: false)
        navigationController?.pushViewController(offlineVC, animated: true)
        offlineVC.openFileFromWidget(with: handle)
    }

    func openNode(base64Handle: String) {
        legacyHomeRouter.showNode(base64Handle)
    }

    private func route(to shortcutType: ShortcutType) {
        switch shortcutType {
        case .audios:
            showAudios()
        case .offline:
            showOffline()
        case .favourites:
            assertionFailure("Handled favourites shortcut in the Home package")
        }
    }

    private func showOffline() {
        let offlineVC = UIStoryboard(name: "Offline", bundle: nil)
            .instantiateViewController(withIdentifier: "OfflineViewControllerID")
        navigationController?.pushViewController(offlineVC, animated: true)
    }

    private func showCameraUploadsOnboarding() {
        guard let navigationController else { return }
        let permissionHandler = DevicePermissionsHandler.makeHandler()
        Task {
            let isGranted = if permissionHandler.shouldAskForPhotosPermissions {
                await PermissionOnboardingRouter(permissionsHandler: permissionHandler)
                    .presentCameraUploadsOnboarding(from: navigationController)
            } else {
                await permissionHandler.requestPhotoLibraryAccessPermissions()
            }
            if isGranted {
                showCameraUploadsSettings()
            } else {
                PermissionAlertRouter.makeRouter(deviceHandler: permissionHandler).alertPhotosPermission()
            }
        }
    }

    private func showCameraUploadsSettings() {
        let cameraUploadsSettingsViewController = CameraUploadsSettingsViewRouter(presenter: navigationController) {}.build()
        cameraUploadsSettingsViewController.hidesBottomBarWhenPushed = true
        TransferIndicatorBarItemConfigurator.injectIfNeeded(into: cameraUploadsSettingsViewController)
        navigationController?.pushViewController(cameraUploadsSettingsViewController, animated: true)
    }

    private func showInviteContacts() {
        let inviteContactViewController = UIStoryboard(name: "InviteContact", bundle: nil)
            .instantiateViewController(withIdentifier: "InviteContactViewControllerID")
        inviteContactViewController.hidesBottomBarWhenPushed = true
        TransferIndicatorBarItemConfigurator.injectIfNeeded(into: inviteContactViewController)
        navigationController?.pushViewController(inviteContactViewController, animated: true)
    }

    private func showAlbum(_ album: AlbumEntity) {
        let albumNavigationController = MEGANavigationController()
        let router = AlbumContentRouter(navigationController: albumNavigationController, album: album, newAlbumPhotos: nil)
        albumNavigationController.setViewControllers([router.build()], animated: false)
        albumNavigationController.modalPresentationStyle = .fullScreen
        navigationController?.present(albumNavigationController, animated: true)
    }

    private func showTransfers() {
        transfersRouter.showTransfers()
    }

    private func showScheduleMeeting() {
        guard let navigationController else { return }
        let viewConfiguration = ScheduleMeetingNewViewConfiguration(
            chatRoomUseCase: ChatRoomUseCase(chatRoomRepo: ChatRoomRepository.newRepo),
            chatLinkUseCase: ChatLinkUseCase(chatLinkRepository: ChatLinkRepository.newRepo),
            scheduledMeetingUseCase: ScheduledMeetingUseCase(repository: ScheduledMeetingRepository.newRepo)
        )
        ScheduleMeetingRouter(
            presenter: navigationController,
            viewConfiguration: viewConfiguration,
            shareLinkRouter: shareLinkRouter
        ).start()
    }
    
    private func showAudios() {
        guard let navigationController else {
            assertionFailure("Navigation controller is nil when trying to push videos explorer view")
            return
        }

        FilesExplorerRouter(navigationController: navigationController, explorerType: .audio).start()
    }

    private func showUpgradePlanView() {
        let accountUseCase = AccountUseCase(repository: AccountRepository.newRepo)
        guard let accountDetails = accountUseCase.currentAccountDetails else {
            MEGALogDebug("[Upgrade Account] Account details are empty")
            return
        }

        SubscriptionPurchaseRouter(
            presenter: UIApplication.mnz_visibleViewController(),
            currentAccountDetails: accountDetails,
            viewType: .upgrade,
            accountUseCase: accountUseCase,
            isFromAds: false)
        .start()
    }

    private func showPromoLandingDialog() {
        PromoLandingDialogRouter
            .makeDefault(presenter: UIApplication.mnz_visibleViewController())
            .start()
    }

    /// Routes through the same path the app uses for a link typed into Open link.
    private func openViewedLink(_ url: URL) {
        MEGALinkManager.adapterLinkURL = url
        MEGALinkManager.processLinkURL(url)
    }

    private func routeToPromotionalUrl(_ url: URL) {
        guard let navigationController else {
            assertionFailure("Navigation controller is nil when trying to route to promotional url \(url)")
            return
        }

        HomeBannerRouter(navigationController: navigationController)
            .didTrigger(from: .universalLink(url))
    }
}
