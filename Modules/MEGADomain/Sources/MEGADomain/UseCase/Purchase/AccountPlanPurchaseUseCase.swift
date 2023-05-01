
public protocol AccountPlanPurchaseUseCaseProtocol {
    func accountPlanProducts() -> [AccountPlanEntity]
}

public struct AccountPlanPurchaseUseCase<T: AccountPlanPurchaseRepositoryProtocol>: AccountPlanPurchaseUseCaseProtocol {
    private let repo: T
    
    public init(repository: T) {
        repo = repository
    }
    
    public func accountPlanProducts() -> [AccountPlanEntity] {
        repo.accountPlanProducts()
    }
}
