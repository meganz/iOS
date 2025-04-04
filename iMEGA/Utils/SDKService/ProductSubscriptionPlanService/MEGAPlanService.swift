import Foundation
import MEGAAppSDKRepo
import MEGAFoundation

final class MEGAPlanCommand: NSObject {

    // MARK: - Typealias

    typealias MEGAPlanFetchResult = Result<[MEGAPlan], MEGAPlanService.DataObtainingError>

    // MARK: - Properties

    fileprivate var completionAction: (MEGAPlanFetchResult) -> Void

    // MARK: - Lifecycles

    init(completionAction: @escaping (MEGAPlanFetchResult) -> Void) {
        self.completionAction = completionAction
    }

    // MARK: - Exposed Methods

    fileprivate func execute(
        with api: MEGASdk,
        cachedPlans: [MEGAPlan]?,
        completion: @escaping (MEGAPlanCommand?, MEGAPlanFetchResult) -> Void
    ) {
        guard let cachedPlans = cachedPlans else {
            fetchMEGAPlans(with: api, completionAction: completionAction, completion: completion)
            return
        }
        completionAction(.success(cachedPlans))
        completion(self, .success(cachedPlans))
    }

    // MARK: - Privates

    fileprivate func fetchMEGAPlans(
        with api: MEGASdk,
        completionAction: @escaping (MEGAPlanFetchResult) -> Void,
        completion: @escaping (MEGAPlanCommand?, MEGAPlanFetchResult) -> Void
    ) {
        let planLoadingTask = MEGAPlanLoadTask()
        planLoadingTask.start(with: api) { result in
            var taskRetaining: MEGAPlanLoadTask? = planLoadingTask
            defer { taskRetaining = nil }
            _ = taskRetaining

            completionAction(result)
            completion(self, result)
        }
    }
}

private final class MEGAPlanLoadTask {

    // MARK: - Methods

    fileprivate func start(
        with api: MEGASdk,
        completion: @escaping (MEGAPlanCommand.MEGAPlanFetchResult) -> Void) {
            api.getPricingWith(RequestDelegate { [weak self] result in
                guard let self else {
                    assertionFailure("MEGAPlanLoadTask instance is unexpected released.")
                    completion(.failure(.unexpectedlyCancellation))
                    return
                }
                
                switch result {
                case .failure:
                    completion(.failure(.unableToFetchMEGAPlan))
                case .success(let request):
                    guard let pricing = request.pricing,
                        let currency = request.currency else {
                        completion(.failure(.unableToFetchMEGAPlan))
                        return
                    }
                    let fetchedMEGAPlans = self.setupCache(with: pricing, currencyName: currency.currencyName)
                    completion(.success(fetchedMEGAPlans))
                }
            })
        }

    // MARK: - Privates

    private func setupCache(with pricing: MEGAPricing, currencyName: String?) -> [MEGAPlan] {
        return (0..<pricing.products).map { productIndex in
            return MEGAPlan(id: productIndex,
                            storage: .gigabytes(of: pricing.storageGB(atProductIndex: productIndex)),
                            transfer: .gigabytes(of: pricing.transferGB(atProductIndex: productIndex)),
                            subscriptionLife: pricing.months(atProductIndex: productIndex),
                            price: pricing.amount(atProductIndex: productIndex),
                            currency: currencyName,
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

    private var api: MEGASdk = MEGASdk.shared

    // MARK: - Setup MEGA Plan

    func send(_ command: MEGAPlanCommand) {
        commands.append(command)
        command.execute(with: api, cachedPlans: cachedMEGAPlans, completion: completion(ofCommand:with:))
    }

    // MARK: - Privates

    private func completion(ofCommand command: MEGAPlanCommand?, with result: MEGAPlanCommand.MEGAPlanFetchResult) {
        if case let .success(plans) = result { cachePlans(plans) }
        if let command = command { remove(command) }
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
