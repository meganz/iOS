import Foundation

final class MEGAPlanAdviser {
    static func suggestMinimumPlan(ofStorage minimumStorage: NSNumber,
                                   availablePlans: [MEGAPlan]) -> [MEGAPlan] {
        let query: QueryConstraint = .minimumPriceForStorageInBytesGreaterThan(minimumStorage.int64Value)
        return query.run(availablePlans)
    }
}

fileprivate struct QueryConstraint {
    var run: ([MEGAPlan]) -> [MEGAPlan]
}

fileprivate extension QueryConstraint {
    
    /// Query constraint generator that takes a `Int64` type of `minimumStorage` and generates a `QueryConstraint` which only returns
    /// `MEGAPlan`s whose storage space greater than minimum storage provided in the parameter.
    private static let storagGreaterThan: (Int64) -> QueryConstraint = { minStorage in
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
    static let minimumPriceForStorageInBytesGreaterThan: (Int64) -> QueryConstraint = { (storage: Int64) -> QueryConstraint in
        return QueryConstraint { plans in
            QueryConstraint.minimumPrice.run(
                QueryConstraint.storagGreaterThan(storage).run(plans))
        }
    }
}
