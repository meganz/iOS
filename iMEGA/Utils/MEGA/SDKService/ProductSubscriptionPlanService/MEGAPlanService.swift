import Foundation

final class MEGAPlanCommand: NSObject {

    fileprivate var completionAction: ([MEGAPlan]?, MEGAPlanService.DataObtainingError?) -> Void

    init(completionAction: @escaping ([MEGAPlan]?, MEGAPlanService.DataObtainingError?) -> Void) {
        self.completionAction = completionAction
    }

    fileprivate func execute(
        with api: MEGASdk,
        cachedPlans: [MEGAPlan]?,
        completion: @escaping (MEGAPlanCommand?, [MEGAPlan]?, MEGAPlanService.DataObtainingError?) -> Void)
    {
        guard let cachedPlans = cachedPlans else {
            fetchMEGAPlans(with: api, completionAction: completionAction, completion: completion)
            return
        }
        completionAction(cachedPlans, nil)
        completion(self, cachedPlans, nil)
    }

    // MARK: - Privates

    fileprivate func fetchMEGAPlans(
        with api: MEGASdk,
        completionAction: @escaping ([MEGAPlan]?, MEGAPlanService.DataObtainingError?) -> Void,
        completion: @escaping (MEGAPlanCommand?, [MEGAPlan]?, MEGAPlanService.DataObtainingError?) -> Void)
    {
        let planLoadingTask = MEGAPlanLoadTask()
        planLoadingTask.start(with: api) { plans, error in
            var taskRetaining: MEGAPlanLoadTask? = planLoadingTask
            defer { taskRetaining = nil }

            completionAction(plans, error)
            completion(self, plans, error)
        }
    }
}

fileprivate final class MEGAPlanLoadTask {

    // MARK: - Methods

    fileprivate func start(
        with api: MEGASdk,
        completion: @escaping ([MEGAPlan]?, MEGAPlanService.DataObtainingError?) -> Void) {
        api.getPricingWith(MEGAGenericRequestDelegate(completion: { [weak self] request, error in
            guard let self = self else {
                assertionFailure("MEGAPlanLoadTask instance is unexpected released.")
                completion(nil, .unexpectedlyCancellation)
                return
            }

            guard case .apiOk = error.type else {
                completion(nil, .unableToFetchMEGAPlan)
                return
            }

            let fetchedMEGAPlans = self.setupCache(with: request.pricing)
            completion(fetchedMEGAPlans, nil)
        }))
    }

    // MARK: - Privates

    private func setupCache(with pricing: MEGAPricing) -> [MEGAPlan] {
        return (0..<pricing.products).map { productIndex in
            return MEGAPlan(id: productIndex,
                            storage: pricing.storageGB(atProductIndex: productIndex),
                            transfer: pricing.transferGB(atProductIndex: productIndex),
                            subscriptionLife: pricing.months(atProductIndex: productIndex),
                            price: MEGAPlan.Price(price: pricing.amount(atProductIndex: productIndex),
                                                  currency: pricing.currency(atProductIndex: productIndex)),
                            proLevel: pricing.proLevel(atProductIndex: productIndex),
                            description: pricing.description(atProductIndex: productIndex))
        }
    }
}

@objc final class MEGAPlanService: NSObject {

    // MARK: - Static

    static var shared: MEGAPlanService = MEGAPlanService()

    // MARK: - Lifecycle

    private override init() {}

    // MARK: - Instance

    // MARK: - Properties

    private var cachedMEGAPlans: [MEGAPlan]?

    private var commands: [MEGAPlanCommand] = []

    private var api: MEGASdk = MEGASdkManager.sharedMEGASdk()

    // MARK: - Setup MEGA Plan

    func send(_ command: MEGAPlanCommand) {
        commands.append(command)
        command.execute(with: api, cachedPlans: cachedMEGAPlans, completion: completion(ofCommand:with:error:))
    }

    // MARK: - Privates

    private func completion(ofCommand command: MEGAPlanCommand?, with plans: [MEGAPlan]?, error: DataObtainingError?) {
        cachePlans(plans)
        if let command = command {
            remove(command)
        }
    }

    private func cachePlans(_ plans: [MEGAPlan]?) {
        guard cachedMEGAPlans == nil, let plans = plans else { return }
        self.cachedMEGAPlans = plans
    }

    private func remove(_ completedCommand: MEGAPlanCommand) {
        commands.removeAll { command -> Bool in
            command == completedCommand
        }
    }

    enum DataObtainingError: Error {
        case unableToFetchMEGAPlan
        case unexpectedlyCancellation
    }
}
