
final class MockMEGAPurchase: MEGAPurchase {
    private(set) var restorePurchaseCalled = 0
    
    init(productPlans: [MockSKProduct] = []) {
        super.init()
        products = NSMutableArray(array: productPlans)
        restoreDelegateMutableArray = NSMutableArray()
    }
    
    var hasRestoreDelegate: Bool {
        guard let restoreDelegateMutableArray,
                restoreDelegateMutableArray.count > 0 else {
            return false
        }
        return true
    }
    
    override func restore() {
        restorePurchaseCalled += 1
    }

}
