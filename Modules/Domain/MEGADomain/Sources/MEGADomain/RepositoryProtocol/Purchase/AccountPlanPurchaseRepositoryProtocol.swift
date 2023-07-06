import Combine

public protocol AccountPlanPurchaseRepositoryProtocol: RepositoryProtocol {
    func accountPlanProducts() async -> [AccountPlanEntity]
    func restorePurchase() async
    
    var successfulRestorePublisher: AnyPublisher<Void, Never> { get }
    var incompleteRestorePublisher: AnyPublisher<Void, Never> { get }
    var failedRestorePublisher: AnyPublisher<AccountPlanErrorEntity, Never> { get }

    func registerRestoreDelegate() async
    func deRegisterRestoreDelegate() async
}
