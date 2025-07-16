import Combine
import MEGADomain

final public class MockAccountPlanPurchaseUseCase: AccountPlanPurchaseUseCaseProtocol, @unchecked Sendable {
    private var accountPlanProducts: [PlanEntity]
    private let _lowestPlan: PlanEntity
    private let _successfulRestorePublisher: PassthroughSubject<Void, Never>
    private let _incompleteRestorePublisher: PassthroughSubject<Void, Never>
    private let _failedRestorePublisher: PassthroughSubject<AccountPlanErrorEntity, Never>
    private let _purchasePlanResultPublisher: PassthroughSubject<Result<Void, AccountPlanErrorEntity>, Never>
    private let _submitReceiptResultPublisher: PassthroughSubject<Result<Void, AccountPlanErrorEntity>, Never>
    private let _monitorSubmitReceiptPublisher: AnyPublisher<Bool, Never>
    
    public var restorePurchaseCalled = 0
    public var purchasePlanCalled = 0
    public var registerRestoreDelegateCalled = 0
    public var deRegisterRestoreDelegateCalled = 0
    public var registerPurchaseDelegateCalled = 0
    public var deRegisterPurchaseDelegateCalled = 0
    public var monitorSubmitReceiptPublisherCalled = 0

    private let _isSubmittingReceiptAfterPurchase: Bool
    public private(set) var startMonitoringSubmitReceiptAfterPurchaseCalled = 0
    public private(set) var endMonitoringPurchaseReceiptCalled = 0
    
    public init(accountPlanProducts: [PlanEntity] = [],
                lowestPlan: PlanEntity = PlanEntity(),
                successfulRestorePublisher: PassthroughSubject<Void, Never> = PassthroughSubject<Void, Never>(),
                incompleteRestorePublisher: PassthroughSubject<Void, Never> = PassthroughSubject<Void, Never>(),
                failedRestorePublisher: PassthroughSubject<AccountPlanErrorEntity, Never> = PassthroughSubject<AccountPlanErrorEntity, Never>(),
                purchasePlanResultPublisher: PassthroughSubject<Result<Void, AccountPlanErrorEntity>, Never> = PassthroughSubject<Result<Void, AccountPlanErrorEntity>, Never>(),
                submitReceiptResultPublisher: PassthroughSubject<Result<Void, AccountPlanErrorEntity>, Never> = PassthroughSubject<Result<Void, AccountPlanErrorEntity>, Never>(),
                monitorSubmitReceiptPublisher: AnyPublisher<Bool, Never> = Empty().eraseToAnyPublisher(),
                isSubmittingReceiptAfterPurchase: Bool = false
    ) {
        self.accountPlanProducts = accountPlanProducts
        _lowestPlan = lowestPlan
        _successfulRestorePublisher = successfulRestorePublisher
        _incompleteRestorePublisher = incompleteRestorePublisher
        _failedRestorePublisher = failedRestorePublisher
        _purchasePlanResultPublisher = purchasePlanResultPublisher
        _submitReceiptResultPublisher = submitReceiptResultPublisher
        _monitorSubmitReceiptPublisher = monitorSubmitReceiptPublisher
        _isSubmittingReceiptAfterPurchase = isSubmittingReceiptAfterPurchase
    }
    
    public func accountPlanProducts() async -> [PlanEntity] {
        accountPlanProducts
    }
    
    public func lowestPlan() async -> PlanEntity {
        _lowestPlan
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

    public func purchasePlanResultPublisher() -> AnyPublisher<Result<Void, AccountPlanErrorEntity>, Never> {
        _purchasePlanResultPublisher.eraseToAnyPublisher()
    }
    
    public var submitReceiptResultPublisher: AnyPublisher<Result<Void, AccountPlanErrorEntity>, Never> {
        _submitReceiptResultPublisher.eraseToAnyPublisher()
    }

    public var monitorSubmitReceiptAfterPurchase: AnyPublisher<Bool, Never> {
        monitorSubmitReceiptPublisherCalled += 1
        return _monitorSubmitReceiptPublisher
    }
    
    public func purchasePlan(_ plan: PlanEntity) async {
        purchasePlanCalled += 1
    }
    
    public func restorePurchase() {
        restorePurchaseCalled += 1
    }
    
    public func registerRestoreDelegate() async {
        registerRestoreDelegateCalled += 1
    }
    
    public func deRegisterRestoreDelegate() async {
        deRegisterRestoreDelegateCalled += 1
    }
    
    public func registerPurchaseDelegate() async {
        registerPurchaseDelegateCalled += 1
    }
    
    public func deRegisterPurchaseDelegate() async {
        deRegisterPurchaseDelegateCalled += 1
    }
    
    public var isSubmittingReceiptAfterPurchase: Bool {
        _isSubmittingReceiptAfterPurchase
    }
    
    public func startMonitoringSubmitReceiptAfterPurchase() {
        startMonitoringSubmitReceiptAfterPurchaseCalled += 1
    }
    
    public func endMonitoringPurchaseReceipt() {
        endMonitoringPurchaseReceiptCalled += 1
    }
}
