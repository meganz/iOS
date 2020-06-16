import Foundation

final class MEGAPlanAdviser {

    static func suggestPlan(constraints: QueryConstraint,
                            api: MEGASdk,
                            completion: @escaping (MEGAPlanUpgradeAdvice) -> Void) {
        MEGAPlanService.loadMegaPlans(with: api) { plans in
            guard let satisfiedPlan = constraints.run(plans).first else {
                completion(.noSatisfied)
                return
            }
            completion(.upgradeTo(satisfiedPlan))
        }
    }
}

enum MEGAPlanUpgradeAdvice {
    case upgradeTo(MEGAPlan)
    case noSatisfied
}

struct QueryConstraint {

    var run: ([MEGAPlan]) -> [MEGAPlan]

    static let storagGreaterThan: (Int) -> QueryConstraint = { minStorage in
        return QueryConstraint { plans in
            plans.filter {  $0.storage > minStorage }
        }
    }

    static let minimumPrice: QueryConstraint = QueryConstraint { plans in
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
}

struct MEGAPlan {
    typealias DataMeasurementInGB = Int
    typealias DateDurationInMonth = Int
    typealias PriceInCents = Int
    typealias Currency = String
    typealias Price = (price: PriceInCents, currency: Currency)
    typealias Description = String
    typealias MEGASDKProductIndex = Int

    let id: MEGASDKProductIndex
    let storage: DataMeasurementInGB
    let transfer: DataMeasurementInGB
    let subscriptionLife: DateDurationInMonth
    let price: Price
    let proLevel: MEGAAccountType
    let description: Description
}

final class MEGAPlanService {

    // MARK: - Static

    static var shared: MEGAPlanService = MEGAPlanService()

    static func loadMegaPlans(with api: MEGASdk, completion: @escaping ([MEGAPlan]) -> Void) {
        if let cachedMEGAPlans = shared.cachedMEGAPlans {
            completion(cachedMEGAPlans)
            return
        }
        shared.completionAction = completion
        shared.fetchMEGAPlans(with: api)
    }

    // MARK: - Lifecycle

    private init() {}

    // MARK: - Instance

    // MARK: - Properties

    private var cachedMEGAPlans: [MEGAPlan]?

    private var completionAction: (([MEGAPlan]) -> Void)?

    // MARK: - Setup MEGA Plan

    private func fetchMEGAPlans(with api: MEGASdk = MEGASdkManager.sharedMEGASdk()) {
        api.getPricingWith(MEGAGenericRequestDelegate(completion: { [weak self] request, error in
            self?.setup(with: request.pricing)
        }))
    }

    private func setup(with pricing: MEGAPricing) {
        let fetchedMEGAPlans = (0..<pricing.products).map { productIndex in
            return MEGAPlan(id: productIndex,
                            storage: pricing.storageGB(atProductIndex: productIndex),
                            transfer: pricing.transferGB(atProductIndex: productIndex),
                            subscriptionLife: pricing.months(atProductIndex: productIndex),
                            price: MEGAPlan.Price(price: pricing.amount(atProductIndex: productIndex),
                                                  currency: pricing.currency(atProductIndex: productIndex)),
                            proLevel: pricing.proLevel(atProductIndex: productIndex),
                            description: pricing.description(atProductIndex: productIndex))
        }

        cachedMEGAPlans = fetchedMEGAPlans

        if let completionAction = completionAction {
            completionAction(fetchedMEGAPlans)
            self.completionAction = nil
        }
    }
}
