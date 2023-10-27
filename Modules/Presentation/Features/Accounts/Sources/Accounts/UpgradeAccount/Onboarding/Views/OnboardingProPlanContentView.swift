import MEGAL10n
import SwiftUI

struct OnboardingProPlanContentView: View {
    @ObservedObject var viewModel: OnboardingUpgradeAccountViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            
            Text(Strings.Localizable.Onboarding.UpgradeAccount.Content.proPlanFeatureHeader)
                .font(.headline)
                .bold()
            
            ProPlanView(
                imageName: "cloud",
                title: Strings.Localizable.Onboarding.UpgradeAccount.Content.GenerousStorage.title,
                message: viewModel.storageContentMessage
            )
            
            ProPlanView(
                imageName: "pieChart",
                title: Strings.Localizable.Onboarding.UpgradeAccount.Content.TransferSharing.title,
                message: Strings.Localizable.Onboarding.UpgradeAccount.Content.TransferSharing.message
            )
            
            ProPlanView(
                imageName: "securityLock",
                title: Strings.Localizable.Onboarding.UpgradeAccount.Content.AdditionalSecurity.title,
                message: Strings.Localizable.Onboarding.UpgradeAccount.Content.AdditionalSecurity.message
            )
        }
    }
}

private struct ProPlanView: View {
    var imageName: String
    var title: String
    var message: String
    
    var body: some View {
        HStack(spacing: 20) {
            Image(imageName)
            
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
