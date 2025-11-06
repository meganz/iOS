import MEGAL10n
import SwiftUI

public struct UpgradeSectionSubscriptionView: View {
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Strings.Localizable.UpgradeAccountPlan.Header.Title.subscriptionDetails)
                .font(.footnote.weight(.bold))
                .padding(.top)
            
            Text(Strings.Localizable.UpgradeAccountPlan.Message.Text.subscriptionDetails)
                .font(.caption2)
        }
        .frame(maxWidth: .infinity)
    }
}
