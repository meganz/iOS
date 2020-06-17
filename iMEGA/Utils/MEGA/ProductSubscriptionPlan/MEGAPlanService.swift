import Foundation

@objc final class MEGAPlanService: NSObject {

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

    private override init() {}

    // MARK: - Instance

    // MARK: - Properties

    private var cachedMEGAPlans: [MEGAPlan]?

    private var completionAction: (([MEGAPlan]) -> Void)?

    // MARK: - Setup MEGA Plan

    private func fetchMEGAPlans(with api: MEGASdk = MEGASdkManager.sharedMEGASdk()) {
        api.getPricingWith(MEGAGenericRequestDelegate(completion: { [weak self] request, error in
            self?.setupCache(with: request.pricing)
        }))
    }

    private func setupCache(with pricing: MEGAPricing) {
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
