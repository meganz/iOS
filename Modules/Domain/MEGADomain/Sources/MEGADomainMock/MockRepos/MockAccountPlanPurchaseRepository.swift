import MEGADomain

public struct MockAccountPlanPurchaseRepository: AccountPlanPurchaseRepositoryProtocol {
    private let plans: [AccountPlanEntity]
    
    public static var newRepo: MockAccountPlanPurchaseRepository {
        MockAccountPlanPurchaseRepository()
    }
    
    public init(plans: [AccountPlanEntity] = []) {
        self.plans = plans
    }
    
    public func accountPlanProducts() -> [AccountPlanEntity] {
        plans
    }
}
