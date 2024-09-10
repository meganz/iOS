import MEGADesignToken
import MEGAL10n
import SwiftUI

struct OnboardingProPlanHeaderView: View {
    @Environment(\.colorScheme) private var colorScheme
    let lowestPlanPrice: String
    let accountsConfig: AccountsConfig
    var titleFont: Font = .title3
    var descriptionFont: Font = .subheadline
    var showHeaderImage: Bool = true
    var spacing: CGFloat = 10
    
    var body: some View {
        VStack(spacing: spacing) {
            if showHeaderImage {
                Image(uiImage: accountsConfig.onboardingViewAssets.onboardingHeaderImage)
            }
            
            Text(Strings.Localizable.Onboarding.UpgradeAccount.Header.title)
                .font(titleFont)
                .bold()
                .foregroundStyle(
                    TokenColors.Text.primary.swiftUI
                )
            
            Text(Strings.Localizable.Onboarding.UpgradeAccount.Header.subTitle(lowestPlanPrice))
                .font(descriptionFont)
                .multilineTextAlignment(.center)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
        }
    }
}
