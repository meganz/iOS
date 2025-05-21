#if DEBUG
import MEGAAssets

extension AccountsConfig {
    
    @MainActor
    static let preview: AccountsConfig = AccountsConfig(
        onboardingViewAssets: OnboardingViewAssets(
            storageImage: MEGAAssets.UIImage.image(named: "storage"),
            fileSharingImage: MEGAAssets.UIImage.image(named: "fileSharing"),
            backupImage: MEGAAssets.UIImage.image(named: "backup"),
            megaImage: MEGAAssets.UIImage.image(named: "mega"),
            onboardingHeaderImage: MEGAAssets.UIImage.image(named: "onboardingHeader"),
            primaryTextColor: MEGAAssets.Color.color(named: "upgrade_account_primaryText"),
            primaryGrayTextColor: MEGAAssets.Color.color(named: "upgrade_account_primaryGrayText"),
            secondaryTextColor: MEGAAssets.Color.color(named: "upgrade_account_secondaryText"),
            subMessageBackgroundColor: MEGAAssets.Color.color(named: "upgrade_account_subMessageBackground"),
            headerForegroundSelectedColor: MEGAAssets.Color.color(named: "turquoise"),
            headerForegroundUnSelectedColor: MEGAAssets.Color.color(named: "unselectedTint"),
            headerBackgroundColor: MEGAAssets.Color.color(named: "headerBackground"),
            headerStrokeColor: MEGAAssets.Color.color(named: "borderTint"),
            backgroundColor: MEGAAssets.Color.color(named: "bodyBackground"),
            currentPlanTagColor: MEGAAssets.Color.color(named: "currentPlan"),
            recommendedPlanTagColor: MEGAAssets.Color.color(named: "recommended")
        )
    )
}
#endif
