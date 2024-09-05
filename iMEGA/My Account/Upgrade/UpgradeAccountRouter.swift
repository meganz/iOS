import Accounts
import Foundation
import MEGADesignToken
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
    private let abTestProvider: any ABTestProviderProtocol
    
    init(purchase: MEGAPurchase = MEGAPurchase.sharedInstance(),
         abTestProvider: some ABTestProviderProtocol = DIContainer.abTestProvider
    ) {
        self.purchase = purchase
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
        let isDesignTokenEnabled = UIColor.isDesignTokenEnabled()
        let accountsConfig = AccountsConfig(
            onboardingViewAssets: AccountsConfig.OnboardingViewAssets(
                storageImage: .storage,
                fileSharingImage: .fileSharing,
                backupImage: .backup,
                megaImage: .mega,
                onboardingHeaderImage: .onboardingHeader,
                primaryTextColor: isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : MEGAAppColor.Account.upgradeAccountPrimaryText.color,
                primaryGrayTextColor: isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : MEGAAppColor.Account.upgradeAccountPrimaryGrayText.color,
                secondaryTextColor: isDesignTokenEnabled ? TokenColors.Text.secondary.swiftUI : MEGAAppColor.Account.upgradeAccountSecondaryText.color,
                subMessageBackgroundColor: isDesignTokenEnabled ? TokenColors.Notifications.notificationSuccess.swiftUI : MEGAAppColor.Account.upgradeAccountSubMessageBackground.color,
                headerForegroundSelectedColor: isDesignTokenEnabled ? TokenColors.Text.accent.swiftUI : MEGAAppColor.View.turquoise.color,
                headerForegroundUnSelectedColor: isDesignTokenEnabled ? TokenColors.Border.strong.swiftUI : MEGAAppColor.Account.planUnselectedTint.color,
                headerBackgroundColor: isDesignTokenEnabled ? TokenColors.Background.surface1.swiftUI : MEGAAppColor.Account.planHeaderBackground.color,
                headerStrokeColor: isDesignTokenEnabled ? TokenColors.Border.strong.swiftUI : MEGAAppColor.Account.planBorderTint.color,
                backgroundColor: isDesignTokenEnabled ? TokenColors.Background.page.swiftUI : MEGAAppColor.Account.planBodyBackground.color,
                currentPlanTagColor: isDesignTokenEnabled ? TokenColors.Notifications.notificationWarning.swiftUI : MEGAAppColor.Account.currentPlan.color,
                recommendedPlanTagColor: isDesignTokenEnabled ? TokenColors.Notifications.notificationInfo.swiftUI : MEGAAppColor.Account.planRecommended.color
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
            presentNewPlanPage(viewType: .upgrade)
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
