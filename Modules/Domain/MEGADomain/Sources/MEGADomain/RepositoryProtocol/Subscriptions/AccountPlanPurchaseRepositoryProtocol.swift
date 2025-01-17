import Combine

public protocol AccountPlanPurchaseRepositoryProtocol: RepositoryProtocol, Sendable {
    func accountPlanProducts() async -> [PlanEntity]
    func restorePurchase()
    func purchasePlan(_ plan: PlanEntity) async
    
    var successfulRestorePublisher: AnyPublisher<Void, Never> { get }
    var incompleteRestorePublisher: AnyPublisher<Void, Never> { get }
    var failedRestorePublisher: AnyPublisher<AccountPlanErrorEntity, Never> { get }
    var purchasePlanResultPublisher: AnyPublisher<Result<Void, AccountPlanErrorEntity>, Never> { get }
    var submitReceiptResultPublisher: AnyPublisher<Result<Void, AccountPlanErrorEntity>, Never> { get }
    
    func registerRestoreDelegate() async
    func deRegisterRestoreDelegate() async
    func registerPurchaseDelegate() async
    func deRegisterPurchaseDelegate() async
}
