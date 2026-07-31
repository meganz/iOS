import MEGADomain

/// Drives the Pro features list, resolving the headline storage and transfer
/// allowances from the largest plan on offer.
///
/// Falls back to the top published tier when no plans are available, so the list
/// never renders an empty allowance.
struct SubscriptionProFeaturesViewModel {
    private enum Constants {
        static let fallbackMaxPlanStorage = "20 TB"
        static let fallbackMaxPlanTransfer = "240 TB"
    }

    private let plans: [PlanEntity]

    init(plans: [PlanEntity]) {
        self.plans = plans
    }

    var maxPlanStorage: String {
        plans.max { $0.storageLimit < $1.storageLimit }?.storage ?? Constants.fallbackMaxPlanStorage
    }

    var maxPlanTransfer: String {
        plans.max { $0.transferLimit < $1.transferLimit }?.transfer ?? Constants.fallbackMaxPlanTransfer
    }
}
