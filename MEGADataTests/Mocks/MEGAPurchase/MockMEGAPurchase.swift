
final class MockMEGAPurchase: MEGAPurchase {
    private(set) var restorePurchaseCalled = 0
    private(set) var purchasePlanCalled = 0
    
    init(productPlans: [MockSKProduct] = []) {
        super.init()
        products = NSMutableArray(array: productPlans)
        restoreDelegateMutableArray = NSMutableArray()
        purchaseDelegateMutableArray = NSMutableArray()
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
