
public protocol AccountPlanPurchaseRepositoryProtocol: RepositoryProtocol {
    func accountPlanProducts() async -> [AccountPlanEntity]
}
