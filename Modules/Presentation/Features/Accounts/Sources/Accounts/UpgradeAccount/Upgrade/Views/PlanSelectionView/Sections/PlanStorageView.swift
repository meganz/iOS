import MEGADomain
import MEGAL10n
import SwiftUI

public struct PlanStorageView: View {
    public var plan: AccountPlanEntity
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            PlanStorageContentView(title: Strings.Localizable.UpgradeAccountPlan.Plan.Details.storage(plan.storage),
                                  detail: plan.storage)
            PlanStorageContentView(title: Strings.Localizable.UpgradeAccountPlan.Plan.Details.transfer(plan.transfer),
                                  detail: plan.transfer)
        }
    }
}

private struct PlanStorageContentView: View {
    var title: String
    var detail: String
    
    private var detailAttributedText: AttributedString {
        var attributedString = AttributedString(title)
        attributedString.font = .subheadline
        attributedString.foregroundColor = Color("secondaryText")
        
        guard let rangeOfDetail = attributedString.range(of: detail) else {
            return attributedString
        }
        attributedString[rangeOfDetail].foregroundColor = Color("primaryText")
        return attributedString
    }
    
    var body: some View {
        Text(detailAttributedText)
    }
}
