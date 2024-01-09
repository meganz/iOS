import Accounts
import MEGADomain
import MEGASDKRepo
import SwiftUI

final class UpgradeAccountPlanRouter: NSObject {
    private weak var presenter: UIViewController?
    private weak var baseViewController: UIViewController?
    private var accountDetails: AccountDetailsEntity
    
    init(presenter: UIViewController, accountDetails: AccountDetailsEntity) {
        self.presenter = presenter
        self.accountDetails = accountDetails
    }
    
    func build() -> UIViewController {
        let viewModel = UpgradeAccountPlanViewModel(accountDetails: accountDetails,
                                                    accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
                                                    purchaseUseCase: AccountPlanPurchaseUseCase(repository: AccountPlanPurchaseRepository.newRepo))
        let accountsConfigs = AccountsConfig(onboardingViewAssets: AccountsConfig.OnboardingViewAssets(
            primaryTextColor: MEGAAppColor.Account.upgradeAccountPrimaryText.color,
            primaryGrayTextColor: MEGAAppColor.Account.upgradeAccountPrimaryGrayText.color,
            secondaryTextColor: MEGAAppColor.Account.upgradeAccountSecondaryText.color,
            subMessageBackgroundColor: MEGAAppColor.Account.upgradeAccountSubMessageBackground.color,
            headerForegroundSelectedColor: MEGAAppColor.View.turquoise.color,
            headerForegroundUnSelectedColor: MEGAAppColor.Account.planUnselectedTint.color,
            headerBackgroundColor: MEGAAppColor.Account.planHeaderBackground.color,
            headerStrokeColor: MEGAAppColor.Account.planBorderTint.color,
            backgroundColor: MEGAAppColor.Account.planBodyBackground.color,
            currentPlanTagColor: MEGAAppColor.Account.currentPlan.color,
            recommededPlanTagColor: MEGAAppColor.Account.planRecommended.color))
        let upgradeAccountPlanView = UpgradeAccountPlanView(viewModel: viewModel, accountConfigs: accountsConfigs)
        let hostingController = UIHostingController(rootView: upgradeAccountPlanView)
        hostingController.isModalInPresentation = true
        return hostingController
    }
    
    func start() {
        let viewController = build()
        baseViewController = viewController
        presenter?.present(viewController, animated: true)
    }
}
