import MEGADomain
import MEGAL10n
import SwiftUI

struct PlanPricingView: View {
    var plan: AccountPlanEntity
    
    var body: some View {
        VStack {
            Text(plan.formattedPrice)
                .font(.title2)
                .bold()
                .foregroundColor(Color(Colors.UpgradeAccount.primaryText.color))
            
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
