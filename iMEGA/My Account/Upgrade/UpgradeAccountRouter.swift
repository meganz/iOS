import Accounts
import Foundation
import MEGADomain
import MEGAPresentation

final class UpgradeAccountRouter {
    private enum UpgradeAccountError: Error {
        case reachability
        case noProducts
        case newPlanPageRequired
    }
    
    private let purchase: MEGAPurchase
    private let abTestProvider: any ABTestProviderProtocol
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    
    init(purchase: MEGAPurchase = MEGAPurchase.sharedInstance(),
         abTestProvider: some ABTestProviderProtocol = DIContainer.abTestProvider,
         featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider) {
        self.purchase = purchase
        self.abTestProvider = abTestProvider
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
            let viewModel = OnboardingUpgradeAccountViewModel(
                purchaseUseCase: AccountPlanPurchaseUseCase(repository: AccountPlanPurchaseRepository.newRepo), 
                tracker: DIContainer.tracker, 
                viewProPlanAction: {
                    UpgradeAccountRouter(purchase: self.purchase).presentUpgradeTVC()
                }
            )
            OnboardingUpgradeAccountRouter(viewModel: viewModel, presenter: UIApplication.mnz_presentingViewController()).start()
        } else {
            let upgradeAccountNC = UpgradeAccountFactory().createUpgradeAccountChooseAccountType()
            UIApplication.mnz_presentingViewController().present(upgradeAccountNC, animated: true, completion: nil)
        }
    }
    
    // MARK: AB Testing
    private func shouldShowNewPlanPageVariant() async -> Bool {
        await abTestProvider.abTestVariant(for: .upgradePlanRevamp) == .variantA
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
        
        let isNewPlanPageVariant = await shouldShowNewPlanPageVariant()
        guard isNewPlanPageVariant else {
            return true
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
