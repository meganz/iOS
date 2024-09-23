import MEGADomain
import MEGASwift

final class MockMEGAPurchase: MEGAPurchase, @unchecked Sendable {
    @Atomic var restorePurchaseCalled = 0
    @Atomic var purchasePlanCalled = 0
    
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
    
    func simulatePurchase(result: Result<Void, AccountPlanErrorEntity>) {
        guard let delegates = purchaseDelegateMutableArray as? [any MEGAPurchaseDelegate] else { return }
        delegates.forEach {
            switch result {
            case .success:
                $0.successfulPurchase(self)
            case .failure(let error):
                $0.failedPurchase?(error.errorCode, message: error.errorMessage)
            }
        }
    }
    
    func simulateRestore(status: RestorePurchaseStateEntity) {
        guard let delegates = restoreDelegateMutableArray as? [any MEGARestoreDelegate] else { return }
        delegates.forEach {
            switch status {
            case .success:
                $0.successfulRestore(self)
            case .incomplete:
                $0.incompleteRestore?()
            case .failed(let error):
                $0.failedRestore?(error.errorCode, message: error.errorMessage)
            }
        }
    }
    
    override func restore() {
        $restorePurchaseCalled.mutate { $0 += 1 }
    }
    
    override func purchaseProduct(_ product: SKProduct?) {
        $purchasePlanCalled.mutate { $0 += 1 }
    }
}
