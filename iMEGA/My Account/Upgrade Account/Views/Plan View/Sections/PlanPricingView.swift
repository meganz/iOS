import MEGADomain
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
        switch plan.term {
        case .monthly:
            return UpgradeStrings.Localizable.UpgradeAccountPlan.Plan.Details.Pricing.localCurrencyPerMonth(plan.currency)
        case .yearly:
            return UpgradeStrings.Localizable.UpgradeAccountPlan.Plan.Details.Pricing.localCurrencyPerYear(plan.currency)
        case .none: return ""
        }
    }
}
