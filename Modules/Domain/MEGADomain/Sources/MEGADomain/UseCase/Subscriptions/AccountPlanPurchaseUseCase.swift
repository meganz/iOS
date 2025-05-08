import Combine

public protocol AccountPlanPurchaseUseCaseProtocol: Sendable {
    func accountPlanProducts() async -> [PlanEntity]
    func lowestPlan() async -> PlanEntity
    func restorePurchase()
    func purchasePlan(_ plan: PlanEntity) async
    
    var successfulRestorePublisher: AnyPublisher<Void, Never> { get }
    var incompleteRestorePublisher: AnyPublisher<Void, Never> { get }
    var failedRestorePublisher: AnyPublisher<AccountPlanErrorEntity, Never> { get }
    func purchasePlanResultPublisher() -> AnyPublisher<Result<Void, AccountPlanErrorEntity>, Never>
    var submitReceiptResultPublisher: AnyPublisher<Result<Void, AccountPlanErrorEntity>, Never> { get }
    var monitorSubmitReceiptAfterPurchase: AnyPublisher<Bool, Never> { get }
    var isSubmittingReceiptAfterPurchase: Bool { get }
    func startMonitoringSubmitReceiptAfterPurchase()
    func endMonitoringPurchaseReceipt()
    
    func registerRestoreDelegate() async
    func deRegisterRestoreDelegate() async
    func registerPurchaseDelegate() async
    func deRegisterPurchaseDelegate() async
}

public struct AccountPlanPurchaseUseCase<T: AccountPlanPurchaseRepositoryProtocol>: AccountPlanPurchaseUseCaseProtocol, Sendable {
    
    private let repo: T
    private let useAPIPrice: @Sendable () async -> Bool

    public init(
        repository: T,
        useAPIPrice: @Sendable @escaping () async -> Bool
    ) {
        repo = repository
        self.useAPIPrice = useAPIPrice
    }
    
    public func accountPlanProducts() async -> [PlanEntity] {
        await repo.accountPlanProducts(useAPIPrice: await useAPIPrice())
    }
    
    public func lowestPlan() async -> PlanEntity {
        let plans = await accountPlanProducts()
        return plans.sorted(by: { $0.price < $1.price }).first ?? PlanEntity()
    }
    
    public func restorePurchase() {
        repo.restorePurchase()
    }
    
    public func purchasePlan(_ plan: PlanEntity) async {
        await repo.purchasePlan(plan)
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
    
    public var submitReceiptResultPublisher: AnyPublisher<Result<Void, AccountPlanErrorEntity>, Never> {
        repo.submitReceiptResultPublisher    
    }
    
    public var monitorSubmitReceiptAfterPurchase: AnyPublisher<Bool, Never> {
        repo.monitorSubmitReceiptAfterPurchase
    }
    
    public var isSubmittingReceiptAfterPurchase: Bool {
        repo.isSubmittingReceiptAfterPurchase
    }
    
    public func startMonitoringSubmitReceiptAfterPurchase() {
        repo.startMonitoringSubmitReceiptAfterPurchase()
    }
    
    public func endMonitoringPurchaseReceipt() {
        repo.endMonitoringPurchaseReceipt()
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
