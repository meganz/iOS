final class MockMEGAPurchase: MEGAPurchase {
    private(set) var restorePurchaseCalled = 0
    private(set) var purchasePlanCalled = 0
    
    override init() {
        super.init()
        restoreDelegateMutableArray = NSMutableArray()
        purchaseDelegateMutableArray = NSMutableArray()
    }
    
    init(productPlans: [MockSKProduct]) {
        super.init(products: productPlans)
    }
    
    var hasRestoreDelegate: Bool {
        guard let restoreDelegateMutableArray,
              restoreDelegateMutableArray.count > 0 else {
            return false
        }
        return true
    }
    
    var hasPurchaseDelegate: Bool {
        guard let purchaseDelegateMutableArray,
              purchaseDelegateMutableArray.count > 0 else {
            return false
        }
        return true
    }
    
    override func restore() {
        restorePurchaseCalled += 1
    }
    
    override func purchaseProduct(_ product: SKProduct?) {
        purchasePlanCalled += 1
    }
}
