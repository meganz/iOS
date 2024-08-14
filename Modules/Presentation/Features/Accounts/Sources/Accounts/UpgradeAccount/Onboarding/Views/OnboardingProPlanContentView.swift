import MEGAAssets
import MEGADesignToken
import MEGAL10n
import SwiftUI

struct OnboardingProPlanContentView: View {
    @ObservedObject var viewModel: OnboardingUpgradeAccountViewModel
    let accountsConfig: AccountsConfig
    
    var body: some View {
        VStack(spacing: 30) {
            
            ProPlanView(
                image: accountsConfig.onboardingViewAssets.storageImage,
                title: Strings.Localizable.Onboarding.UpgradeAccount.Content.GenerousStorage.title,
                message: viewModel.storageContentMessage
            )
            
            ProPlanView(
                image: accountsConfig.onboardingViewAssets.fileSharingImage,
                title: Strings.Localizable.Onboarding.UpgradeAccount.Content.TransferSharing.title,
                message: Strings.Localizable.Onboarding.UpgradeAccount.Content.TransferSharing.message
            )
            
            ProPlanView(
                image: accountsConfig.onboardingViewAssets.backupImage,
                title: Strings.Localizable.Onboarding.UpgradeAccount.Content.BackupAndRewind.title,
                message: Strings.Localizable.Onboarding.UpgradeAccount.Content.BackupAndRewind.message
            )
            
            ProPlanView(
                image: accountsConfig.onboardingViewAssets.megaImage,
                title: Strings.Localizable.Onboarding.UpgradeAccount.Content.PlusBenefits.title,
                message: viewModel.isAdsEnabled ? Strings.Localizable.Onboarding.UpgradeAccount.Content.PlusBenefits.messageWithAds :
                    Strings.Localizable.Onboarding.UpgradeAccount.Content.PlusBenefits.messageWithoutAds
            )
        }
    }
}

private struct ProPlanView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var image: UIImage?
    var title: String
    var message: String
    
    var body: some View {
        HStack(spacing: 20) {
            Image(uiImage: image)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.subheadline)
                    .bold()
                    .foregroundStyle(
                        isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : Color(.label)
                    )
                
                Text(message)
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(
                        isDesignTokenEnabled ? 
                        TokenColors.Text.secondary.swiftUI :
                            colorScheme == .dark ? Color(red: 181/255, green: 181/255, blue: 181/255) : Color(red: 132/255, green: 132/255, blue: 132/255)
                    )
            }
            
            Spacer()
        }
    }
}

#Preview {
    ProPlanView(image: MEGAAssetsImageProvider.image(named: "storage"), title: "Title", message: "Message")
}
