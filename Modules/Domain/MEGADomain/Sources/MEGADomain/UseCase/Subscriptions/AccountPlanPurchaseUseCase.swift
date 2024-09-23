import MEGASwift

public protocol AccountPlanPurchaseUseCaseProtocol: Sendable {
    func accountPlanProducts() async -> [PlanEntity]
    func restorePurchase()
    func purchasePlan(_ plan: PlanEntity) async
    
    var purchasePlanResultUpdates: AnyAsyncSequence<Result<Void, AccountPlanErrorEntity>> { get }
    var restorePurchaseUpdates: AnyAsyncSequence<RestorePurchaseStateEntity> { get }
}

public struct AccountPlanPurchaseUseCase<T: AccountPlanPurchaseRepositoryProtocol>: AccountPlanPurchaseUseCaseProtocol, Sendable {
    
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
    
    public var purchasePlanResultUpdates: AnyAsyncSequence<Result<Void, AccountPlanErrorEntity>> {
        repo.purchasePlanResultUpdates
    }
    
    public var restorePurchaseUpdates: AnyAsyncSequence<RestorePurchaseStateEntity> {
        repo.restorePurchaseUpdates
    }
}
