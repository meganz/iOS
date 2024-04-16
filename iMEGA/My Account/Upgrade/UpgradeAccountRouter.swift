import Accounts
import Foundation
import MEGADomain
import MEGAPresentation
import MEGASDKRepo

protocol UpgradeAccountRouting {
    func presentUpgradeTVC()
}

final class UpgradeAccountRouter: UpgradeAccountRouting {
    private enum UpgradeAccountError: Error {
        case reachability
        case noProducts
        case newPlanPageRequired
    }
    
    private let purchase: MEGAPurchase
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    
    init(purchase: MEGAPurchase = MEGAPurchase.sharedInstance(),
         featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider) {
        self.purchase = purchase
        self.featureFlagProvider = featureFlagProvider
    }
    
    func pushUpgradeTVC(navigationController: UINavigationController) {
        Task { @MainActor in
            await show {
                let upgradeTVC = UpgradeAccountFactory().createUpgradeAccountTVC()
                navigationController.pushViewController(upgradeTVC, animated: true)
            }
        }
    }
    
    func presentUpgradeTVC() {
        Task { @MainActor in
            await show {
                let upgradeAccountNC = UpgradeAccountFactory().createUpgradeAccountNC()
                UIApplication.mnz_visibleViewController().present(upgradeAccountNC, animated: true)
            }
        }
    }
    
    func presentChooseAccountType() {
        guard let products = purchase.products, products.isNotEmpty else { return }
        
        if featureFlagProvider.isFeatureFlagEnabled(for: .onboardingProPlan) {
            let accountsConfig = AccountsConfig(
                onboardingViewAssets: AccountsConfig.OnboardingViewAssets(
                    storageImage: .storage,
                    fileSharingImage: .fileSharing,
                    backupImage: .backup,
                    vpnImage: .shield,
                    meetingsImage: .meetings,
                    onboardingHeaderImage: .onboardingHeader,
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
                    recommededPlanTagColor: MEGAAppColor.Account.planRecommended.color
                )
            )
            
            OnboardingUpgradeAccountRouter(
                purchaseUseCase: AccountPlanPurchaseUseCase(repository: AccountPlanPurchaseRepository.newRepo),
                accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
                tracker: DIContainer.tracker,
                presenter: UIApplication.mnz_presentingViewController(),
                accountsConfig: accountsConfig,
                viewProPlanAction: {
                    UpgradeAccountRouter(purchase: self.purchase).presentUpgradeTVC()
                }
            ).start()
        } else {
            let upgradeAccountNC = UpgradeAccountFactory().createUpgradeAccountChooseAccountType()
            UIApplication.mnz_presentingViewController().present(upgradeAccountNC, animated: true, completion: nil)
        }
    }
    
    private func presentNewPlanPage() {
        guard let accountDetails = MEGASdk.shared.mnz_accountDetails else { return }
        UpgradeAccountPlanRouter(
            presenter: UIApplication.mnz_presentingViewController(),
            accountDetails: accountDetails.toAccountDetailsEntity()
        ).start()
    }
    
    // MARK: Helpers
    private func shouldPushUpgradeTVC() async throws -> Bool {
        guard try shouldShowPlanPage() else {
            throw UpgradeAccountError.noProducts
        }
        
        throw UpgradeAccountError.newPlanPageRequired
    }
    
    @discardableResult
    private func shouldShowPlanPage() throws -> Bool {
        guard let products = purchase.products, MEGASdk.shared.mnz_accountDetails != nil else {
            throw UpgradeAccountError.reachability
        }
        
        return products.isNotEmpty
    }
    
    private func handle(error: any Error) {
        switch error {
        case UpgradeAccountError.reachability:
            MEGAReachabilityManager.isReachableHUDIfNot()
        case UpgradeAccountError.newPlanPageRequired:
            presentNewPlanPage()
        default:
            MEGALogError("[Upgrade Account] Could not show the upgrade with error \(error)")
        }
    }
    
    @MainActor
    private func show(upgradeAccount: @escaping () -> Void) async {
        do {
            guard try await shouldPushUpgradeTVC() else { return }
            upgradeAccount()
        } catch {
            handle(error: error)
        }
    }
}
