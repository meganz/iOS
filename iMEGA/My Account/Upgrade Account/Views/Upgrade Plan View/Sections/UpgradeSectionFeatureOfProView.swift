import SwiftUI

struct UpgradeSectionFeatureOfProView: View {
    var body: some View {
        VStack {
            Text(Strings.Localizable.UpgradeAccountPlan.Header.Title.featuresOfProPlan)
                .font(.title3)
                .bold()
            
            Text(Strings.Localizable.UpgradeAccountPlan.Message.Text.featuresOfProPlan)
            .multilineTextAlignment(.leading)
            .font(.callout)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
