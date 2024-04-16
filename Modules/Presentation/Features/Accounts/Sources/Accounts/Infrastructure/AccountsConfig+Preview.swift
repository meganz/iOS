#if DEBUG
import MEGAAssets

extension AccountsConfig {
    
    static let preview: AccountsConfig = AccountsConfig(
        onboardingViewAssets: OnboardingViewAssets(
            storageImage: MEGAAssetsPreviewImageProvider.image(named: "storage"),
            fileSharingImage: MEGAAssetsPreviewImageProvider.image(named: "fileSharing"),
            backupImage: MEGAAssetsPreviewImageProvider.image(named: "backup"),
            vpnImage: MEGAAssetsPreviewImageProvider.image(named: "shield"),
            meetingsImage: MEGAAssetsPreviewImageProvider.image(named: "meetings"),
            onboardingHeaderImage: MEGAAssetsPreviewImageProvider.image(named: "onboardingHeader"),
            primaryTextColor: MEGAAssetsPreviewColorProvider.swiftUIColor(named: "upgrade_account_primaryText"),
            primaryGrayTextColor: MEGAAssetsPreviewColorProvider.swiftUIColor(named: "upgrade_account_primaryGrayText"),
            secondaryTextColor: MEGAAssetsPreviewColorProvider.swiftUIColor(named: "upgrade_account_secondaryText"),
            subMessageBackgroundColor: MEGAAssetsPreviewColorProvider.swiftUIColor(named: "upgrade_account_subMessageBackground"),
            headerForegroundSelectedColor: MEGAAssetsPreviewColorProvider.swiftUIColor(named: "turquoise"),
            headerForegroundUnSelectedColor: MEGAAssetsPreviewColorProvider.swiftUIColor(named: "unselectedTint"),
            headerBackgroundColor: MEGAAssetsPreviewColorProvider.swiftUIColor(named: "headerBackground"),
            headerStrokeColor: MEGAAssetsPreviewColorProvider.swiftUIColor(named: "borderTint"),
            backgroundColor: MEGAAssetsPreviewColorProvider.swiftUIColor(named: "bodyBackground"),
            currentPlanTagColor: MEGAAssetsPreviewColorProvider.swiftUIColor(named: "currentPlan"),
            recommededPlanTagColor: MEGAAssetsPreviewColorProvider.swiftUIColor(named: "recommended")
        )
    )
}
#endif
