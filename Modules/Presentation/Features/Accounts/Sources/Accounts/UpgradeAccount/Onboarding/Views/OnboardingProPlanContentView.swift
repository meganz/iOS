import MEGADesignToken
import MEGAL10n
import SwiftUI

struct OnboardingProPlanContentView: View {
    @ObservedObject var viewModel: OnboardingUpgradeAccountViewModel
    let accountsConfig: AccountsConfig
    
    var body: some View {
        VStack(spacing: 30) {
            
            ProPlanFeatureView(
                image: accountsConfig.onboardingViewAssets.storageImage,
                title: Strings.Localizable.Onboarding.UpgradeAccount.Content.GenerousStorage.title,
                message: viewModel.storageContentMessage
            )
            
            ProPlanFeatureView(
                image: accountsConfig.onboardingViewAssets.fileSharingImage,
                title: Strings.Localizable.Onboarding.UpgradeAccount.Content.TransferSharing.title,
                message: Strings.Localizable.Onboarding.UpgradeAccount.Content.TransferSharing.message
            )
            
            ProPlanFeatureView(
                image: accountsConfig.onboardingViewAssets.backupImage,
                title: Strings.Localizable.Onboarding.UpgradeAccount.Content.BackupAndRewind.title,
                message: Strings.Localizable.Onboarding.UpgradeAccount.Content.BackupAndRewind.message
            )
            
            ProPlanFeatureView(
                image: accountsConfig.onboardingViewAssets.megaImage,
                title: Strings.Localizable.Onboarding.UpgradeAccount.Content.PlusBenefits.title,
                message: viewModel.isAdsEnabled ? Strings.Localizable.Onboarding.UpgradeAccount.Content.PlusBenefits.messageWithAds :
                    Strings.Localizable.Onboarding.UpgradeAccount.Content.PlusBenefits.messageWithoutAds
            )
        }
    }
}
