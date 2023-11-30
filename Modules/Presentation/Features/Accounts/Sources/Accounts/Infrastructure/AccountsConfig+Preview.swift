#if DEBUG
import MEGAAssets

extension AccountsConfig {
    
    static let preview: AccountsConfig = AccountsConfig(
        onboardingViewAssets: OnboardingViewAssets(
            cloudImage: MEGAAssetsPreviewImageProvider.image(named: "cloud"),
            pieChartImage: MEGAAssetsPreviewImageProvider.image(named: "pieChartImage"),
            securityLockImage: MEGAAssetsPreviewImageProvider.image(named: "securityLock"),
            onboardingHeaderImage: MEGAAssetsPreviewImageProvider.image(named: "onboardingHeader")
        )
    )
}
#endif
