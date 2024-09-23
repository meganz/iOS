import MEGADomain
import MEGASwift

public final class MockAccountPlanPurchaseRepository: AccountPlanPurchaseRepositoryProtocol, @unchecked Sendable {
    private let plans: [PlanEntity]
    public var restorePurchaseCalled = 0
    public var purchasePlanCalled = 0
    
    // MARK: - Purchase updates
    public let purchasePlanResultUpdates: AnyAsyncSequence<Result<Void, AccountPlanErrorEntity>>
    public let restorePurchaseUpdates: AnyAsyncSequence<RestorePurchaseStateEntity>
    
    public static var newRepo: MockAccountPlanPurchaseRepository {
        MockAccountPlanPurchaseRepository()
    }
    
    public init(
        plans: [PlanEntity] = [],
        purchasePlanResultUpdates: AnyAsyncSequence<Result<Void, AccountPlanErrorEntity>> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        restorePurchaseUpdates: AnyAsyncSequence<RestorePurchaseStateEntity> = EmptyAsyncSequence().eraseToAnyAsyncSequence()
    ) {
        self.plans = plans
        self.purchasePlanResultUpdates = purchasePlanResultUpdates
        self.restorePurchaseUpdates = restorePurchaseUpdates
    }
    
    public func accountPlanProducts() -> [PlanEntity] {
        plans
    }
    
    public func restorePurchase() {
        restorePurchaseCalled += 1
    }
    
    public func purchasePlan(_ plan: PlanEntity) async {
        purchasePlanCalled += 1
    }
}
