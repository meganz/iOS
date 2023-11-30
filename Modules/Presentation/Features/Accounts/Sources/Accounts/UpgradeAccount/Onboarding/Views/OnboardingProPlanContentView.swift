import MEGAAssets
import MEGAL10n
import SwiftUI

struct OnboardingProPlanContentView: View {
    @ObservedObject var viewModel: OnboardingUpgradeAccountViewModel
    let accountsConfig: AccountsConfig
    
    var body: some View {
        VStack(spacing: 30) {
            
            Text(Strings.Localizable.Onboarding.UpgradeAccount.Content.proPlanFeatureHeader)
                .font(.headline)
                .bold()
            
            ProPlanView(
                image: accountsConfig.onboardingViewAssets.cloudImage,
                title: Strings.Localizable.Onboarding.UpgradeAccount.Content.GenerousStorage.title,
                message: viewModel.storageContentMessage
            )
            
            ProPlanView(
                image: accountsConfig.onboardingViewAssets.pieChartImage,
                title: Strings.Localizable.Onboarding.UpgradeAccount.Content.TransferSharing.title,
                message: Strings.Localizable.Onboarding.UpgradeAccount.Content.TransferSharing.message
            )
            
            ProPlanView(
                image: accountsConfig.onboardingViewAssets.securityLockImage,
                title: Strings.Localizable.Onboarding.UpgradeAccount.Content.AdditionalSecurity.title,
                message: Strings.Localizable.Onboarding.UpgradeAccount.Content.AdditionalSecurity.message
            )
        }
    }
}

private struct ProPlanView: View {
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
                
                Text(message)
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
    }
}

struct ProPlanView_Previews: PreviewProvider {
    static var previews: some View {
        ProPlanView(image: MEGAAssetsPreviewImageProvider.image(named: "cloud"), title: "Title", message: "Message")
    }
}
