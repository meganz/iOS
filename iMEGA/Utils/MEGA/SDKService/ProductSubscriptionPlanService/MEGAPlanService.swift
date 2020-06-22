import Foundation

final class MEGAPlanCommand: NSObject {

    fileprivate var completionAction: ([MEGAPlan]) -> Void

    init(completionAction: @escaping ([MEGAPlan]) -> Void) {
        self.completionAction = completionAction
    }

    fileprivate func execute(with api: MEGASdk,
                             cachedPlans: [MEGAPlan]?,
                             completion: @escaping (MEGAPlanCommand, [MEGAPlan]) -> Void) {
        if let cachedPlans = cachedPlans {
            completionAction(cachedPlans)
            completion(self, cachedPlans)
            return
        }

        fetchMEGAPlans(with: api, completion: completion)
    }

    // MARK: - Privates

    fileprivate func fetchMEGAPlans(with api: MEGASdk, completion: @escaping (MEGAPlanCommand, [MEGAPlan]) -> Void) {
        let planLoadingTask = MEGAPlanLoadTask()
        planLoadingTask.start(with: api) { [weak self] plans in
            var taskRetaining: MEGAPlanLoadTask? = planLoadingTask
            defer { taskRetaining = nil }

            guard let self = self else { return }
            self.completionAction(plans)
            completion(self, plans)
        }
    }
}

fileprivate final class MEGAPlanLoadTask {

    // MARK: - Instances

    fileprivate var plans: [MEGAPlan]?

    // MARK: - Methods

    fileprivate func start(with api: MEGASdk, completion: @escaping ([MEGAPlan]) -> Void) {
        api.getPricingWith(MEGAGenericRequestDelegate(completion: { [weak self] request, error in
            guard let self = self else { return }
            let fetchedMEGAPlans = self.setupCache(with: request.pricing)
            self.plans = fetchedMEGAPlans
            completion(fetchedMEGAPlans)
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
        command.execute(with: api, cachedPlans: cachedMEGAPlans, completion: completion(ofCommand:with:))
    }

    // MARK: - Privates

    private func completion(ofCommand command: MEGAPlanCommand, with plans: [MEGAPlan]) {
        cachePlans(plans)
        remove(command)
    }

    private func cachePlans(_ plans: [MEGAPlan]) {
        guard cachedMEGAPlans == nil else { return }
        self.cachedMEGAPlans = plans
    }

    private func remove(_ completedCommand: MEGAPlanCommand) {
        commands.removeAll { command -> Bool in
            command == completedCommand
        }
    }
}
