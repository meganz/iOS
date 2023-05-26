import MEGADomain

public struct MockAccountPlanPurchaseUseCase: AccountPlanPurchaseUseCaseProtocol {
    private var accountPlanProducts: [AccountPlanEntity]
    
    public init(accountPlanProducts: [AccountPlanEntity] = []) {
        self.accountPlanProducts = accountPlanProducts
    }
    
    public func accountPlanProducts() async -> [AccountPlanEntity] {
        accountPlanProducts
    }
    
}
