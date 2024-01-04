import MEGAL10n
import SwiftUI

struct UpgradeSectionFeatureOfProView: View {
    var showAdFreeContent: Bool
    
    var body: some View {
        VStack {
            Text(Strings.Localizable.UpgradeAccountPlan.Header.Title.featuresOfProPlan)
                .font(.title3)
                .bold()
            
            Text(showAdFreeContent ? Strings.Localizable.UpgradeAccountPlan.Message.Text.featuresOfProPlanWithAds : Strings.Localizable.UpgradeAccountPlan.Message.Text.featuresOfProPlan)
            .multilineTextAlignment(.leading)
            .font(.callout)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
