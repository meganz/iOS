import MEGADomain
import MEGASwift

final public class MockAccountPlanPurchaseUseCase: AccountPlanPurchaseUseCaseProtocol, @unchecked Sendable {
    private var accountPlanProducts: [PlanEntity]
    public var restorePurchaseCalled = 0
    public var purchasePlanCalled = 0
    
    // MARK: - Purchase updates
    public let purchasePlanResultUpdates: AnyAsyncSequence<Result<Void, AccountPlanErrorEntity>>
    public let restorePurchaseUpdates: AnyAsyncSequence<RestorePurchaseStateEntity>
    
    public init(
        accountPlanProducts: [PlanEntity] = [],
        purchasePlanResultUpdates: AnyAsyncSequence<Result<Void, AccountPlanErrorEntity>> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        restorePurchaseUpdates: AnyAsyncSequence<RestorePurchaseStateEntity> = EmptyAsyncSequence().eraseToAnyAsyncSequence()
    ) {
        self.accountPlanProducts = accountPlanProducts
        self.purchasePlanResultUpdates = purchasePlanResultUpdates
        self.restorePurchaseUpdates = restorePurchaseUpdates
    }
    
    public func accountPlanProducts() async -> [PlanEntity] {
        accountPlanProducts
    }
    
    public func purchasePlan(_ plan: PlanEntity) async {
        purchasePlanCalled += 1
    }
    
    public func restorePurchase() {
        restorePurchaseCalled += 1
    }
}
