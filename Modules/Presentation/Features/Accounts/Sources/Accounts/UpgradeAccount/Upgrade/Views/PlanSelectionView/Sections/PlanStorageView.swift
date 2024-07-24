import MEGADomain
import MEGAL10n
import SwiftUI

public struct PlanStorageView: View {
    public var plan: PlanEntity
    public var primaryTextColor: Color
    public var secondaryTextColor: Color
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            PlanStorageContentView(title: Strings.Localizable.UpgradeAccountPlan.Plan.Details.storage(plan.storage),
                                  detail: plan.storage, primaryTextColor: primaryTextColor, secondaryTextColor: secondaryTextColor)
            PlanStorageContentView(title: Strings.Localizable.UpgradeAccountPlan.Plan.Details.transfer(plan.transfer),
                                  detail: plan.transfer, primaryTextColor: primaryTextColor, secondaryTextColor: secondaryTextColor)
        }
    }
}

private struct PlanStorageContentView: View {
    var title: String
    var detail: String
    var primaryTextColor: Color
    var secondaryTextColor: Color
    
    private var detailAttributedText: AttributedString {
        var attributedString = AttributedString(title)
        attributedString.font = .subheadline
        attributedString.foregroundColor = secondaryTextColor
        
        guard let rangeOfDetail = attributedString.range(of: detail) else {
            return attributedString
        }
        
        attributedString[rangeOfDetail].foregroundColor = primaryTextColor
        return attributedString
    }
    
    var body: some View {
        Text(detailAttributedText)
    }
}
