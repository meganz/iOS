import Foundation
import MEGAFoundation

enum MEGAPlanUpgradeAdviser {
    static func suggestMinimumPlan(for currentPlan: MEGAPlan? = nil,
                                   ofStorage minimumStorage: Measurement<UnitDataStorage>,
                                   from availablePlans: [MEGAPlan]) -> MEGAPlanUpgradeAdvice {
        let filter: QueryConstraint = .minimumPriceForStorageInBytesGreaterThan(minimumStorage)
        let plansMeetCriteria = filter(availablePlans)

        guard let foundPlan = plansMeetCriteria.first else {
            return .noSuitablePlan
        }

        if foundPlan == currentPlan {
            return .noNeedUpgrade
        }

        return .upgrade(to: foundPlan)
    }
}

enum MEGAPlanUpgradeAdvice {
    case upgrade(to: MEGAPlan)
    case noSuitablePlan
    case noNeedUpgrade

    var plan: MEGAPlan? {
        switch self {
        case .noNeedUpgrade, .noSuitablePlan: return nil
        case .upgrade(to: let newPlan): return newPlan
        }
    }
}

private struct QueryConstraint {
    var run: ([MEGAPlan]) -> [MEGAPlan]

    func callAsFunction(_ plans: [MEGAPlan]) -> [MEGAPlan] {
        return run(plans)
    }
}

private extension QueryConstraint {
    
    /// Query constraint generator that takes a `Double` type of `minimumStorage` and generates a `QueryConstraint` which only returns
    /// `MEGAPlan`s whose storage space greater than minimum storage provided in the parameter.
    private static let storagGreaterThan: (Measurement<UnitDataStorage>) -> QueryConstraint = { minStorage in
        return QueryConstraint { plans in
            plans.filter {  $0.storageSpaceInBytes > minStorage }
        }
    }

    /// Query constraint that find the lowest price `MEGAPlan` in provided plans.
    private static let minimumPrice: QueryConstraint = QueryConstraint { plans in
        return plans.reduce([]) { (result: [MEGAPlan], plan: MEGAPlan) in
            guard let bestPrice = result.first?.price else {
                return [plan]
            }
            if bestPrice > plan.price {
                return [plan]
            }
            return result
        }
    }
    
    /// A composite query constraint who composite `storagGreaterThan` and `mimumPrice` together.
    static let minimumPriceForStorageInBytesGreaterThan: (Measurement<UnitDataStorage>) -> QueryConstraint = { (storage) -> QueryConstraint in
        return QueryConstraint { plans in
            QueryConstraint.minimumPrice(
                QueryConstraint.storagGreaterThan(storage)(plans))
        }
    }
}
