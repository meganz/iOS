import Foundation

final class MEGAPlanCommand: NSObject {

    fileprivate var completionAction: ([MEGAPlan]) -> Void

    private var loadingTask: MEGAPlanLoadTask?

    init(completionAction: @escaping ([MEGAPlan]) -> Void) {
        self.completionAction = completionAction
    }

    func execute(with api: MEGASdk, completion: @escaping (MEGAPlanCommand) -> Void) {
        let planLoadingTask = MEGAPlanLoadTask()
        planLoadingTask.start(with: api) { [weak self] plans in
            guard let self = self else { return }
            self.completionAction(plans)
            completion(self)
        }
        loadingTask = planLoadingTask
    }
}

fileprivate final class MEGAPlanLoadTask {

    fileprivate func start(with api: MEGASdk, completion: @escaping ([MEGAPlan]) -> Void) {
        api.getPricingWith(MEGAGenericRequestDelegate(completion: { [weak self] request, error in
            guard let self = self else { return }
            let fetchMEGAPlans = self.setupCache(with: request.pricing)
            completion(fetchMEGAPlans)
        }))
    }

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
        guard let cachedMEGAPlans = cachedMEGAPlans else {
            let originalCommandCompletion = command.completionAction
            command.completionAction = { [weak self] plans in
                guard let self = self else {
                    return
                }
                self.cachedMEGAPlans = plans
                originalCommandCompletion(plans)
            }

            command.execute(with: api) { [weak self] completedCommand in
                guard let self = self else {
                    return
                }
                self.remove(command)
            }
            return
        }
        command.completionAction(cachedMEGAPlans)
    }

    private func remove(_ completedCommand: MEGAPlanCommand) {
        commands.removeAll { command -> Bool in
            command == completedCommand
        }
    }
}
