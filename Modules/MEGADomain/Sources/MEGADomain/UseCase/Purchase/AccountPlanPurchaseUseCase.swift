
public protocol AccountPlanPurchaseUseCaseProtocol {
    func accountPlanProducts() async -> [AccountPlanEntity]
}

public struct AccountPlanPurchaseUseCase<T: AccountPlanPurchaseRepositoryProtocol>: AccountPlanPurchaseUseCaseProtocol {
    private let repo: T
    
    public init(repository: T) {
        repo = repository
    }
    
    public func accountPlanProducts() async -> [AccountPlanEntity] {
        await repo.accountPlanProducts()
    }
}
