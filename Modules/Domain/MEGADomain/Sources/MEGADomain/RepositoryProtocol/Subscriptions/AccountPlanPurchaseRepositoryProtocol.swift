import MEGASwift

public protocol AccountPlanPurchaseRepositoryProtocol: RepositoryProtocol, Sendable {
    func accountPlanProducts() async -> [PlanEntity]
    func restorePurchase()
    func purchasePlan(_ plan: PlanEntity) async
  
    var purchasePlanResultUpdates: AnyAsyncSequence<Result<Void, AccountPlanErrorEntity>> { get }
    var restorePurchaseUpdates: AnyAsyncSequence<RestorePurchaseStateEntity> { get }
}
