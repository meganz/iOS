import MEGAAppSDKRepoMock

final class MockMEGAPurchase: MEGAPurchase, @unchecked Sendable {
    private(set) var restorePurchaseCalled = 0
    private(set) var purchasePlanCalled = 0

    var _pricing: MEGAPricing?
    var _currency: MEGACurrency?

    override init() {
        super.init()
        restoreDelegateMutableArray = NSMutableArray()
        purchaseDelegateMutableArray = NSMutableArray()
    }
    
    init(productPlans: [MockSKProduct] = [], isSubmittingReceipt: Bool = false) {
        super.init(products: productPlans)
        setIsSubmittingReceipt(isSubmittingReceipt)
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

    override var pricing: MEGAPricing! {
        get { _pricing ?? super.pricing }
        set { _pricing = newValue }
    }

    override var currency: MEGACurrency! {
        get { _currency ?? super.currency }
        set { _currency = newValue }
    }

    override func restore() {
        restorePurchaseCalled += 1
    }
    
    override func purchaseProduct(_ product: SKProduct?) {
        purchasePlanCalled += 1
    }
}
