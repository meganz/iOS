import Foundation

extension MEGAPurchase {
    func requestPricingAsync() async {
        guard products == nil || products.isEmpty else { return }
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            _ = DelegateHolder(purchase: self, continuation: continuation)
            self.requestPricing()
        }
    }

    private final class DelegateHolder: NSObject, MEGAPurchasePricingDelegate {
        let continuation: CheckedContinuation<Void, Never>
        let purchase: MEGAPurchase

        init(purchase: MEGAPurchase, continuation: CheckedContinuation<Void, Never>) {
            self.purchase = purchase
            self.continuation = continuation
            super.init()
            purchase.pricingsDelegateMutableArray.add(self)
        }

        func pricingsReady() {
            continuation.resume()
            purchase.pricingsDelegateMutableArray.remove(self)
        }
    }
}
