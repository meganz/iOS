import MEGAAppSDKRepo
import MEGADomain
import MEGAPreference
import SwiftUI
import UIKit

extension UIViewController {
    @objc func createAvatarBarButtonItem() -> UIBarButtonItem {
        let contentView = UIHostingConfiguration {
            MyAvatarIconView { [weak self] in
                self?.didTapAvatarItem()
            }
        }
        .margins(.all, 0)
        .makeContentView()
        
        return UIBarButtonItem(customView: contentView)
    }
    
    private func didTapAvatarItem() {
        guard let navigationController else { return }
        MyAccountHallRouter(
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
            navigationController: navigationController
        ).start()
    }
}
