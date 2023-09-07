import Foundation
import MEGAPresentation

final class UpgradeAccountRouter {
    private enum UpgradeAccountError: Error {
        case reachability
        case noProducts
        case newPlanPageRequired
    }
    
    private var abTestProvider: any ABTestProviderProtocol
    
    init(abTestProvider: some ABTestProviderProtocol = DIContainer.abTestProvider) {
        self.abTestProvider = abTestProvider
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
        do {
            try shouldShowPlanPage()
        } catch {
            handle(error: error)
        }
        
        let upgradeAccountNC = UpgradeAccountFactory().createUpgradeAccountChooseAccountType()
        UIApplication.mnz_visibleViewController().present(upgradeAccountNC, animated: true, completion: nil)
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
        guard let products = MEGAPurchase.sharedInstance().products, MEGASdk.shared.mnz_accountDetails != nil else {
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
