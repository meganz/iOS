import Combine
import MEGADomain

final public class MockAccountPlanPurchaseUseCase: AccountPlanPurchaseUseCaseProtocol {
    private var accountPlanProducts: [AccountPlanEntity]
    private let _successfulRestorePublisher: PassthroughSubject<Void, Never>
    private let _incompleteRestorePublisher: PassthroughSubject<Void, Never>
    private let _failedRestorePublisher: PassthroughSubject<AccountPlanErrorEntity, Never>
    
    public var restorePurchaseCalled = 0
    public var registerRestoreDelegateCalled = 0
    public var deRegisterRestoreDelegateCalled = 0
    
    public init(accountPlanProducts: [AccountPlanEntity] = [],
                successfulRestorePublisher: PassthroughSubject<Void, Never> = PassthroughSubject<Void, Never>(),
                incompleteRestorePublisher: PassthroughSubject<Void, Never> = PassthroughSubject<Void, Never>(),
                failedRestorePublisher: PassthroughSubject<AccountPlanErrorEntity, Never> = PassthroughSubject<AccountPlanErrorEntity, Never>()) {
        self.accountPlanProducts = accountPlanProducts
        _successfulRestorePublisher = successfulRestorePublisher
        _incompleteRestorePublisher = incompleteRestorePublisher
        _failedRestorePublisher = failedRestorePublisher
    }
    
    public func accountPlanProducts() async -> [AccountPlanEntity] {
        accountPlanProducts
    }
    
    public var successfulRestorePublisher: AnyPublisher<Void, Never> {
        _successfulRestorePublisher.eraseToAnyPublisher()
    }
    
    public var incompleteRestorePublisher: AnyPublisher<Void, Never> {
        _incompleteRestorePublisher.eraseToAnyPublisher()
    }
    
    public var failedRestorePublisher: AnyPublisher<AccountPlanErrorEntity, Never> {
        _failedRestorePublisher.eraseToAnyPublisher()
    }
    
    public func restorePurchase() async {
        restorePurchaseCalled += 1
    }
    
    public func registerRestoreDelegate() async {
        registerRestoreDelegateCalled += 1
    }
    
    public func deRegisterRestoreDelegate() async {
        deRegisterRestoreDelegateCalled += 1
    }
}
