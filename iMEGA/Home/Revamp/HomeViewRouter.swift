import Home
import MEGAAppSDKRepo
import MEGADomain
import SwiftUI
import UIKit

@MainActor
final class HomeViewRouter: HomeViewRouting {
    private weak var navigationController: UINavigationController?

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func route(to type: HomeWidgetRouteType) {
        switch type {
        case .shortcut(let shortcutType):
            route(to: shortcutType)
        case .accountUpgrade:
            showUpgradePlanView()
        }
    }

    private func route(to shortcutType: ShortcutType) {
        switch shortcutType {
        case .videos:
            showVideos()
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

    private func showVideos() {
        guard let navigationController else {
            assertionFailure("Navigation controller is nil when trying to push videos explorer view")
            return
        }

        FilesExplorerRouter(navigationController: navigationController, explorerType: .video).start()
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
}
