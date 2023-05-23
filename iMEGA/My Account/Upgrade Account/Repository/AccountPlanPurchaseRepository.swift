import MEGADomain

struct AccountPlanPurchaseRepository: AccountPlanPurchaseRepositoryProtocol {
    static var newRepo: AccountPlanPurchaseRepository {
        AccountPlanPurchaseRepository(purchase: MEGAPurchase.sharedInstance())
    }
    
    private let purchase: MEGAPurchase
    
    init(purchase: MEGAPurchase) {
        self.purchase = purchase
    }
    
    func accountPlanProducts() async -> [AccountPlanEntity] {
        guard let products = purchase.products as? [SKProduct] else { return [] }

        var accountPlans: [AccountPlanEntity] = []
        for (index, product) in products.enumerated() {
            let plan = product.toAccountPlanEntity(
                product: product,
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
