import Combine
import MEGADomain

public final class MockAccountPlanPurchaseRepository: AccountPlanPurchaseRepositoryProtocol {

    private let plans: [AccountPlanEntity]
    public let successfulRestorePublisher: AnyPublisher<Void, Never>
    public let incompleteRestorePublisher: AnyPublisher<Void, Never>
    public let failedRestorePublisher: AnyPublisher<AccountPlanErrorEntity, Never>
    public var registerRestoreDelegateCalled = 0
    public var deRegisterRestoreDelegateCalled = 0
    public var restorePurchaseCalled = 0
    
    public static var newRepo: MockAccountPlanPurchaseRepository {
        MockAccountPlanPurchaseRepository()
    }
    
    public init(plans: [AccountPlanEntity] = [],
                successfulRestorePublisher: AnyPublisher<Void, Never> = Empty().eraseToAnyPublisher(),
                incompleteRestorePublisher: AnyPublisher<Void, Never> = Empty().eraseToAnyPublisher(),
                failedRestorePublisher: AnyPublisher<AccountPlanErrorEntity, Never> = Empty().eraseToAnyPublisher()) {
        self.plans = plans
        self.successfulRestorePublisher = successfulRestorePublisher
        self.incompleteRestorePublisher = incompleteRestorePublisher
        self.failedRestorePublisher = failedRestorePublisher
    }
    
    public func accountPlanProducts() -> [AccountPlanEntity] {
        plans
    }
    
    public func registerRestoreDelegate() async {
        registerRestoreDelegateCalled += 1
    }
    
    public func deRegisterRestoreDelegate() async {
        deRegisterRestoreDelegateCalled += 1
    }
    
    public func restorePurchase() async {
        restorePurchaseCalled += 1
    }
}
