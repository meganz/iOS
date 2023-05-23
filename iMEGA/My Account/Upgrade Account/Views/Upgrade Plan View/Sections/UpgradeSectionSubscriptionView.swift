import SwiftUI

struct UpgradeSectionSubscriptionView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(UpgradeStrings.Localizable.UpgradeAccountPlan.Header.Title.subscriptionDetails)
                .font(.footnote.weight(.bold))
                .padding(.top)
            
            Text(UpgradeStrings.Localizable.UpgradeAccountPlan.Message.Text.subscriptionDetails)
                .font(.caption2)
        }
        .frame(maxWidth: .infinity)
    }
}
