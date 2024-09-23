import MEGADomain
import MEGASdk
import MEGASDKRepo
import MEGASwift

final class AccountPlanPurchaseRepository: NSObject, AccountPlanPurchaseRepositoryProtocol, Sendable {
    static var newRepo: AccountPlanPurchaseRepository {
        AccountPlanPurchaseRepository(
            purchase: MEGAPurchase.sharedInstance(),
            purchaseUpdatesProvider: AccountPlanPurchaseUpdatesProvider(purchase: MEGAPurchase.sharedInstance()))
    }
    
    private let purchase: MEGAPurchase
    private let purchaseUpdatesProvider: any AccountPlanPurchaseUpdatesProviderProtocol
    
    init(
        purchase: MEGAPurchase,
        purchaseUpdatesProvider: some AccountPlanPurchaseUpdatesProviderProtocol
    ) {
        self.purchase = purchase
        self.purchaseUpdatesProvider = purchaseUpdatesProvider
    }

    func restorePurchase() {
        purchase.restore()
    }
    
    @MainActor
    func purchasePlan(_ plan: PlanEntity) async {
        guard let products = purchase.products as? [SKProduct],
              let productPlan = products.first(where: { $0.productIdentifier == plan.productIdentifier }) else {
            return
        }
        purchase.purchaseProduct(productPlan)
    }
    
    var restorePurchaseUpdates: AnyAsyncSequence<RestorePurchaseStateEntity> {
        purchaseUpdatesProvider.restorePurchaseUpdates
    }
    
    var purchasePlanResultUpdates: AnyAsyncSequence<Result<Void, AccountPlanErrorEntity>> {
        purchaseUpdatesProvider.purchasePlanResultUpdates
    }
    
    func accountPlanProducts() async -> [PlanEntity] {
        guard let products = purchase.products as? [SKProduct] else { return [] }

        var accountPlans: [PlanEntity] = []
        for product in products {
            // We need to find out where the current product is listed in our `MEGAPricing instance because sometimes
            // there's a mismatch between the products listed in the SDK/API and those available in the Apple Store.
            // This discrepancy can occur when new products are added to the SDK/API but haven't been added to the Apple Store yet.
            let productIndex = purchase.pricingProductIndex(for: product)
            let plan = product.toPlanEntity(
                storage: storageGB(atProductIndex: Int(productIndex)),
                transfer: transferGB(atProductIndex: Int(productIndex))
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
