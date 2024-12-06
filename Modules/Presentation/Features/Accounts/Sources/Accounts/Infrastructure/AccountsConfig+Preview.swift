#if DEBUG
import MEGAAssets

extension AccountsConfig {
    
    @MainActor
    static let preview: AccountsConfig = AccountsConfig(
        onboardingViewAssets: OnboardingViewAssets(
            storageImage: MEGAAssetsImageProvider.image(named: "storage"),
            fileSharingImage: MEGAAssetsImageProvider.image(named: "fileSharing"),
            backupImage: MEGAAssetsImageProvider.image(named: "backup"),
            megaImage: MEGAAssetsImageProvider.image(named: "mega"),
            onboardingHeaderImage: MEGAAssetsImageProvider.image(named: "onboardingHeader"),
            primaryTextColor: MEGAAssetsColorProvider.swiftUIColor(named: "upgrade_account_primaryText"),
            primaryGrayTextColor: MEGAAssetsColorProvider.swiftUIColor(named: "upgrade_account_primaryGrayText"),
            secondaryTextColor: MEGAAssetsColorProvider.swiftUIColor(named: "upgrade_account_secondaryText"),
            subMessageBackgroundColor: MEGAAssetsColorProvider.swiftUIColor(named: "upgrade_account_subMessageBackground"),
            headerForegroundSelectedColor: MEGAAssetsColorProvider.swiftUIColor(named: "turquoise"),
            headerForegroundUnSelectedColor: MEGAAssetsColorProvider.swiftUIColor(named: "unselectedTint"),
            headerBackgroundColor: MEGAAssetsColorProvider.swiftUIColor(named: "headerBackground"),
            headerStrokeColor: MEGAAssetsColorProvider.swiftUIColor(named: "borderTint"),
            backgroundColor: MEGAAssetsColorProvider.swiftUIColor(named: "bodyBackground"),
            currentPlanTagColor: MEGAAssetsColorProvider.swiftUIColor(named: "currentPlan"),
            recommendedPlanTagColor: MEGAAssetsColorProvider.swiftUIColor(named: "recommended")
        )
    )
}
#endif
