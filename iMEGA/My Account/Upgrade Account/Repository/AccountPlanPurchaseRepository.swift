import Combine
import MEGADomain

final class AccountPlanPurchaseRepository: NSObject, AccountPlanPurchaseRepositoryProtocol {

    static var newRepo: AccountPlanPurchaseRepository {
        AccountPlanPurchaseRepository(purchase: MEGAPurchase.sharedInstance())
    }
    
    private let purchase: MEGAPurchase
    
    private let successfulRestoreSourcePublisher = PassthroughSubject<Void, Never>()
    var successfulRestorePublisher: AnyPublisher<Void, Never> {
        successfulRestoreSourcePublisher.eraseToAnyPublisher()
    }
    
    private let incompleteRestoreSourcePublisher = PassthroughSubject<Void, Never>()
    var incompleteRestorePublisher: AnyPublisher<Void, Never> {
        incompleteRestoreSourcePublisher.eraseToAnyPublisher()
    }
    
    private let failedRestoreSourcePublisher = PassthroughSubject<AccountPlanErrorEntity, Never>()
    var failedRestorePublisher: AnyPublisher<AccountPlanErrorEntity, Never> {
        failedRestoreSourcePublisher.eraseToAnyPublisher()
    }
    
    private let purchasePlanResultSourcePublisher = PassthroughSubject<Result<Void, AccountPlanErrorEntity>, Never>()
    var purchasePlanResultPublisher: AnyPublisher<Result<Void, AccountPlanErrorEntity>, Never> {
        purchasePlanResultSourcePublisher.eraseToAnyPublisher()
    }
    
    init(purchase: MEGAPurchase) {
        self.purchase = purchase
    }
    
    func registerRestoreDelegate() async {
        purchase.restoreDelegateMutableArray.add(self)
    }
    
    func deRegisterRestoreDelegate() async {
        purchase.restoreDelegateMutableArray.remove(self)
    }
    
    func registerPurchaseDelegate() async {
        purchase.purchaseDelegateMutableArray.add(self)
    }
    
    func deRegisterPurchaseDelegate() async {
        purchase.purchaseDelegateMutableArray.remove(self)
    }

    func restorePurchase() async {
        purchase.restore()
    }
    
    func purchasePlan(_ plan: AccountPlanEntity) async {
        guard let products = purchase.products as? [SKProduct],
              let productPlan = products.first(where: { $0.productIdentifier == plan.productIdentifier }) else {
            return
        }
        purchase.purchaseProduct(productPlan)
    }
    
    func accountPlanProducts() async -> [AccountPlanEntity] {
        guard let products = purchase.products as? [SKProduct] else { return [] }

        var accountPlans: [AccountPlanEntity] = []
        for (index, product) in products.enumerated() {
            let plan = product.toAccountPlanEntity(
                storage: storageGB(atProductIndex: index),
                transfer: transferGB(atProductIndex: index)
            )
            accountPlans.append(plan)
        }
        
        return accountPlans
    }
    
    private func storageGB(atProductIndex index: Int) -> Int {
        guard let pricing = purchase.pricing else { return 0 }
        return pricing.storageGB(atProductIndex: index)
    }
    
    private func transferGB(atProductIndex index: Int) -> Int {
        guard let pricing = purchase.pricing else { return 0 }
        return pricing.transferGB(atProductIndex: index)
    }
}

// MARK: - MEGARequestDelegate
extension AccountPlanPurchaseRepository: MEGARestoreDelegate {
    func successfulRestore(_ megaPurchase: MEGAPurchase?) {
        successfulRestoreSourcePublisher.send()
    }
    
    func incompleteRestore() {
        incompleteRestoreSourcePublisher.send()
    }
    
    func failedRestore(_ errorCode: Int, message errorMessage: String!) {
        let error = AccountPlanErrorEntity(errorCode: errorCode, errorMessage: errorMessage)
        failedRestoreSourcePublisher.send(error)
    }
}

// MARK: - MEGAPurchaseDelegate
extension AccountPlanPurchaseRepository: MEGAPurchaseDelegate {
    func successfulPurchase(_ megaPurchase: MEGAPurchase?) {
        purchasePlanResultSourcePublisher.send(.success(()))
    }
    
    func failedPurchase(_ errorCode: Int, message errorMessage: String?) {
        let error = AccountPlanErrorEntity(errorCode: errorCode, errorMessage: errorMessage)
        purchasePlanResultSourcePublisher.send(.failure(error))
    }
}
