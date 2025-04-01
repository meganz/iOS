import Accounts
import Foundation
import MEGAAppPresentation
import MEGADesignToken
import MEGADomain
import MEGASDKRepo

@MainActor
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
    private let abTestProvider: any ABTestProviderProtocol
    
    nonisolated init(
        purchase: MEGAPurchase = MEGAPurchase.sharedInstance(),
        abTestProvider: some ABTestProviderProtocol = DIContainer.abTestProvider
    ) {
        self.purchase = purchase
        self.abTestProvider = abTestProvider
    }
    
    func pushUpgradeTVC(navigationController: UINavigationController) {
        show {
            let upgradeTVC = UpgradeAccountFactory().createUpgradeAccountTVC()
            navigationController.pushViewController(upgradeTVC, animated: true)
        }
    }
    
    func presentUpgradeTVC() {
        show {
            let upgradeAccountNC = UpgradeAccountFactory().createUpgradeAccountNC()
            UIApplication.mnz_visibleViewController().present(upgradeAccountNC, animated: true)
        }
    }
    
    func presentChooseAccountType() {
        guard let products = purchase.products, products.isNotEmpty else { return }
        let achievementsUseCase = AchievementUseCase(repo: AchievementRepository.newRepo)

        Task { @MainActor in
            guard let baseStorage = try? await achievementsUseCase.baseStorage().bytesToGigabytes() else {
                MEGALogError("Error fetching account base storage")
                return
            }
            
            let onboardingVariant = await abTestProvider.abTestVariant(for: .onboardingUpsellingDialog)
            
            guard onboardingVariant != .baseline else {
                presentUpgradeAccountChooseAccountType(
                    accountBaseStorage: baseStorage
                )
                return
            }
            
            let isAdsEnabled = await abTestProvider.abTestVariant(for: .ads) == .variantA
            
            presentOnboardingUpsellingDialog(
                onboardingVariant: onboardingVariant,
                isAdsEnabled: isAdsEnabled,
                baseStorage: baseStorage
            )
        }
    }
    
    private func presentUpgradeAccountChooseAccountType(accountBaseStorage: Int) {
        let upgradeAccountNC = UpgradeAccountFactory().createUpgradeAccountChooseAccountType(accountBaseStorage: accountBaseStorage)
        UIApplication.mnz_presentingViewController().present(upgradeAccountNC, animated: true, completion: nil)
    }
    
    private func presentOnboardingUpsellingDialog(
        onboardingVariant: ABTestVariant,
        isAdsEnabled: Bool,
        baseStorage: Int
    ) {
        let accountsConfig = AccountsConfig(
            onboardingViewAssets: AccountsConfig.OnboardingViewAssets(
                storageImage: .storage,
                fileSharingImage: .fileSharing,
                backupImage: .backup,
                megaImage: .mega,
                onboardingHeaderImage: .onboardingHeader,
                primaryTextColor: TokenColors.Text.primary.swiftUI,
                primaryGrayTextColor: TokenColors.Text.primary.swiftUI,
                secondaryTextColor: TokenColors.Text.secondary.swiftUI,
                subMessageBackgroundColor: TokenColors.Notifications.notificationSuccess.swiftUI,
                headerForegroundSelectedColor: TokenColors.Text.accent.swiftUI,
                headerForegroundUnSelectedColor: TokenColors.Border.strong.swiftUI,
                headerBackgroundColor: TokenColors.Background.surface1.swiftUI,
                headerStrokeColor: TokenColors.Border.strong.swiftUI,
                backgroundColor: TokenColors.Background.page.swiftUI,
                currentPlanTagColor: TokenColors.Notifications.notificationWarning.swiftUI,
                recommendedPlanTagColor: TokenColors.Notifications.notificationInfo.swiftUI
            )
        )
        
        OnboardingUpgradeAccountRouter(
            purchaseUseCase: AccountPlanPurchaseUseCase(repository: AccountPlanPurchaseRepository.newRepo),
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
            tracker: DIContainer.tracker,
            onboardingABvariant: onboardingVariant,
            presenter: UIApplication.mnz_presentingViewController(),
            accountsConfig: accountsConfig,
            isAdsEnabled: isAdsEnabled,
            baseStorage: baseStorage,
            viewProPlanAction: {
                UpgradeAccountRouter().presentNewPlanPage(viewType: .onboarding)
            }
        ).start()
    }
    
    private func presentNewPlanPage(viewType: UpgradeAccountPlanViewType) {
        guard let accountDetails = MEGASdk.shared.mnz_accountDetails else { return }
        UpgradeAccountPlanRouter(
            presenter: UIApplication.mnz_presentingViewController(),
            accountDetails: accountDetails.toAccountDetailsEntity(), 
            viewType: viewType
        ).start()
    }
    
    // MARK: Helpers
    private func shouldPushUpgradeTVC() throws -> Bool {
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
            presentNewPlanPage(viewType: .upgrade)
        default:
            MEGALogError("[Upgrade Account] Could not show the upgrade with error \(error)")
        }
    }
    
    private func show(upgradeAccount: @escaping () -> Void) {
        do {
            guard try shouldPushUpgradeTVC() else { return }
            upgradeAccount()
        } catch {
            handle(error: error)
        }
    }
}
