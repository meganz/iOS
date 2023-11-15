import MEGADomain
import MEGAL10n
import SwiftUI

struct PlanStorageView: View {
    var plan: AccountPlanEntity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            PlanStorageDetailView(title: Strings.Localizable.UpgradeAccountPlan.Plan.Details.storage(plan.storage),
                                  detail: plan.storage)
            PlanStorageDetailView(title: Strings.Localizable.UpgradeAccountPlan.Plan.Details.transfer(plan.transfer),
                                  detail: plan.transfer)
        }
    }
}

struct PlanStorageDetailView: View {
    var title: String
    var detail: String
    
    private var detailAttributedText: AttributedString {
        var attributedString = AttributedString(title)
        attributedString.font = .subheadline
        attributedString.foregroundColor = Color(Colors.UpgradeAccount.secondaryText.color)
        
        guard let rangeOfDetail = attributedString.range(of: detail) else {
            return attributedString
        }
        attributedString[rangeOfDetail].foregroundColor = Color(Colors.UpgradeAccount.primaryText.color)
        return attributedString
    }
    
    var body: some View {
        Text(detailAttributedText)
    }
}
