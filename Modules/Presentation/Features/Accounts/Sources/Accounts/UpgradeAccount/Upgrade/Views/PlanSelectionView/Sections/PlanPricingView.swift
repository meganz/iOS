import MEGADomain
import MEGAL10n
import SwiftUI

public struct PlanPricingView: View {
    public var plan: AccountPlanEntity
    
    public var body: some View {
        VStack {
            Text(plan.formattedPrice)
                .font(.title2)
                .bold()
                .foregroundColor(Color("primaryText"))
            
            Text(currencyPerTermString)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
    
    private var currencyPerTermString: String {
        switch plan.subscriptionCycle {
        case .monthly:
            return Strings.Localizable.UpgradeAccountPlan.Plan.Details.Pricing.localCurrencyPerMonth(plan.currency)
        case .yearly:
            return Strings.Localizable.UpgradeAccountPlan.Plan.Details.Pricing.localCurrencyPerYear(plan.currency)
        case .none: return ""
        }
    }
}
