import Foundation

final class MEGAPlanAdviser {
    static func suggestMinimumPlan(ofStorage minimumStorage: Measurement<UnitDataStorage>,
                                   availablePlans: [MEGAPlan]) -> [MEGAPlan] {
        let query: QueryConstraint = .minimumPriceForStorageInBytesGreaterThan(minimumStorage)
        return query.run(availablePlans)
    }
}

fileprivate struct QueryConstraint {
    var run: ([MEGAPlan]) -> [MEGAPlan]
}

fileprivate extension QueryConstraint {
    
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
            guard let bestPrice = result.first?.price.price else {
                return [plan]
            }
            if bestPrice > plan.price.price {
                return [plan]
            }
            return result
        }
    }
    
    /// A composite query constraint who composite `storagGreaterThan` and `mimumPrice` together.
    static let minimumPriceForStorageInBytesGreaterThan: (Measurement<UnitDataStorage>) -> QueryConstraint = {
        (storage) -> QueryConstraint in
        return QueryConstraint { plans in
            QueryConstraint.minimumPrice.run(
                QueryConstraint.storagGreaterThan(storage).run(plans))
        }
    }
}
