import Combine

public protocol AccountPlanPurchaseUseCaseProtocol {
    func accountPlanProducts() async -> [AccountPlanEntity]
    func restorePurchase() async
    
    var successfulRestorePublisher: AnyPublisher<Void, Never> { get }
    var incompleteRestorePublisher: AnyPublisher<Void, Never> { get }
    var failedRestorePublisher: AnyPublisher<AccountPlanErrorEntity, Never> { get }
    
    func registerRestoreDelegate() async
    func deRegisterRestoreDelegate() async
}

public struct AccountPlanPurchaseUseCase<T: AccountPlanPurchaseRepositoryProtocol>: AccountPlanPurchaseUseCaseProtocol {
    private let repo: T
    
    public init(repository: T) {
        repo = repository
    }
    
    public func accountPlanProducts() async -> [AccountPlanEntity] {
        await repo.accountPlanProducts()
    }
    
    public func restorePurchase() async {
        await repo.restorePurchase()
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
    
    public func registerRestoreDelegate() async {
        await repo.registerRestoreDelegate()
    }
    
    public func deRegisterRestoreDelegate() async {
        await repo.deRegisterRestoreDelegate()
    }
}
