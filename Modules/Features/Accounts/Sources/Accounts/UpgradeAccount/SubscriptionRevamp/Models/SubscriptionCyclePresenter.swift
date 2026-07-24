import Foundation
import MEGADomain
import MEGAL10n

/// Presents the billing-cycle picker: the available cycles, their titles, and the yearly saving text.
struct SubscriptionCyclePresenter {
    let plans: [PlanEntity]

    var options: [SubscriptionCycleEntity] {
        let available = Set(plans.map(\.subscriptionCycle))
        return [.monthly, .yearly].filter(available.contains)
    }

    func title(for cycle: SubscriptionCycleEntity) -> String {
        switch cycle {
        case .monthly: Strings.Localizable.monthly
        case .yearly: Strings.Localizable.yearly
        case .none: ""
        }
    }

    var savingText: String? {
        guard let percentage = maxYearlySavingPercentage, percentage > 0 else { return nil }
        return Strings.Localizable.SubscriptionPurchase.Revamp.Cycle.saving("\(percentage)%")
    }

    // [IOS-12292]: Compute the correct percentage in case offers are present
    private var maxYearlySavingPercentage: Int? {
        let monthlyPriceByType = Dictionary(
            plans.filter { $0.subscriptionCycle == .monthly }.map { ($0.type, $0.price) },
            uniquingKeysWith: { first, _ in first }
        )
        let savings: [Int] = plans
            .filter { $0.subscriptionCycle == .yearly }
            .compactMap { yearly in
                guard let monthlyPrice = monthlyPriceByType[yearly.type], monthlyPrice > 0 else { return nil }
                let ratio = (yearly.price / 12) / monthlyPrice
                let percentage = NSDecimalNumber(decimal: (1 - ratio) * 100).rounding(accordingToBehavior: nil).intValue
                return percentage > 0 ? percentage : nil
            }
        return savings.max()
    }
}
