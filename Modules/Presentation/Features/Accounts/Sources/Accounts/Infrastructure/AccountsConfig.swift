import SwiftUI
import UIKit

/// Any configuration needed for account module assets, behaviour or styling
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
        
        public let primaryTextColor: Color
        public let primaryGrayTextColor: Color
        public let secondaryTextColor: Color
        public let subMessageBackgroundColor: Color
        public let headerForegroundSelectedColor: Color
        public let headerForegroundUnSelectedColor: Color
        public let headerBackgroundColor: Color
        public let headerStrokeColor: Color
        public let backgroundColor: Color
        public let currentPlanTagColor: Color
        public let recommededPlanTagColor: Color
        
        public init(
            cloudImage: UIImage? = nil,
            pieChartImage: UIImage? = nil,
            securityLockImage: UIImage? = nil,
            onboardingHeaderImage: UIImage? = nil,
            primaryTextColor: Color,
            primaryGrayTextColor: Color,
            secondaryTextColor: Color,
            subMessageBackgroundColor: Color,
            headerForegroundSelectedColor: Color,
            headerForegroundUnSelectedColor: Color,
            headerBackgroundColor: Color,
            headerStrokeColor: Color,
            backgroundColor: Color,
            currentPlanTagColor: Color,
            recommededPlanTagColor: Color
        ) {
            self.cloudImage = cloudImage
            self.pieChartImage = pieChartImage
            self.securityLockImage = securityLockImage
            self.onboardingHeaderImage = onboardingHeaderImage
            self.primaryGrayTextColor = primaryGrayTextColor
            self.primaryTextColor = primaryTextColor
            self.secondaryTextColor = secondaryTextColor
            self.subMessageBackgroundColor = subMessageBackgroundColor
            self.headerForegroundSelectedColor = headerForegroundSelectedColor
            self.headerForegroundUnSelectedColor = headerForegroundUnSelectedColor
            self.headerBackgroundColor = headerBackgroundColor
            self.headerStrokeColor = headerStrokeColor
            self.backgroundColor = backgroundColor
            self.currentPlanTagColor = currentPlanTagColor
            self.recommededPlanTagColor = recommededPlanTagColor
        }
    }
}
