import Combine

public protocol AccountPlanPurchaseUseCaseProtocol {
    func accountPlanProducts() async -> [PlanEntity]
    func restorePurchase()
    func purchasePlan(_ plan: PlanEntity) async
    func cancelCreditCardSubscriptions(reason: String?) async throws
    
    var successfulRestorePublisher: AnyPublisher<Void, Never> { get }
    var incompleteRestorePublisher: AnyPublisher<Void, Never> { get }
    var failedRestorePublisher: AnyPublisher<AccountPlanErrorEntity, Never> { get }
    func purchasePlanResultPublisher() -> AnyPublisher<Result<Void, AccountPlanErrorEntity>, Never>
    
    func registerRestoreDelegate() async
    func deRegisterRestoreDelegate() async
    func registerPurchaseDelegate() async
    func deRegisterPurchaseDelegate() async
}

public struct AccountPlanPurchaseUseCase<T: AccountPlanPurchaseRepositoryProtocol>: AccountPlanPurchaseUseCaseProtocol {
    
    private let repo: T
    
    public init(repository: T) {
        repo = repository
    }
    
    public func accountPlanProducts() async -> [PlanEntity] {
        await repo.accountPlanProducts()
    }
    
    public func restorePurchase() {
        repo.restorePurchase()
    }
    
    public func purchasePlan(_ plan: PlanEntity) async {
        await repo.purchasePlan(plan)
    }
    
    public func cancelCreditCardSubscriptions(reason: String?) async throws {
        try await repo.cancelCreditCardSubscriptions(reason: reason)
    }

    public var successfulRestorePublisher: AnyPublisher<Void, Never> {
        repo.successfulRestorePublisher
    }
    
    public var incompleteRestorePublisher: AnyPublisher<Void, Never> {
        repo.incompleteRestorePublisher
    }
    
    public var failedRestorePublisher: AnyPublisher<AccountPlanErrorEntity, Never> {
        repo.failedRestorePublisher
    }
    
    public func purchasePlanResultPublisher() -> AnyPublisher<Result<Void, AccountPlanErrorEntity>, Never> {
        repo.purchasePlanResultPublisher
    }
    
    public func registerRestoreDelegate() async {
        await repo.registerRestoreDelegate()
    }
    
    public func deRegisterRestoreDelegate() async {
        await repo.deRegisterRestoreDelegate()
    }
    
    public func registerPurchaseDelegate() async {
        await repo.registerPurchaseDelegate()
    }
    
    public func deRegisterPurchaseDelegate() async {
        await repo.deRegisterPurchaseDelegate()
    }
}
