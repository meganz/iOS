import UIKit

/// Any configuration needed for search module assets, behaviour or styling
public struct AccountsConfig {
    
    public let onboardingViewAssets: OnboardingViewAssets
    
    public init(
        onboardingViewAssets: AccountsConfig.OnboardingViewAssets
    ) {
        self.onboardingViewAssets = onboardingViewAssets
    }
    
    public struct OnboardingViewAssets {
        public let cloudImage: UIImage?
        public let pieChartImage: UIImage?
        public let securityLockImage: UIImage?
        public let onboardingHeaderImage: UIImage?
        
        public init(
            cloudImage: UIImage?,
            pieChartImage: UIImage?,
            securityLockImage: UIImage?,
            onboardingHeaderImage: UIImage?
        ) {
            self.cloudImage = cloudImage
            self.pieChartImage = pieChartImage
            self.securityLockImage = securityLockImage
            self.onboardingHeaderImage = onboardingHeaderImage
        }
    }
}
