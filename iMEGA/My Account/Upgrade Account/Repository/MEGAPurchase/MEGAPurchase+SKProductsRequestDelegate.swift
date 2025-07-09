import StoreKit

extension MEGAPurchase: SKProductsRequestDelegate {
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        MEGALogDebug("[StoreKit] Products request did receive response \(response.products.count) products")
        let sortedProducts = response.products.sorted { $0.productIdentifier < $1.productIdentifier }
        for product in sortedProducts {
            MEGALogDebug("[StoreKit] Product \(product.productIdentifier) received")
            self.products.add(product)
        }

        for productIdentifier in response.invalidProductIdentifiers {
            MEGALogError("[StoreKit] Invalid product \(productIdentifier)")
        }

        DispatchQueue.main.async {
            self.pricingDelegateOnPricingReady()
        }
    }

    public func request(_ request: SKRequest, didFailWithError error: any Error) {
        MEGALogError("[StoreKit] Request did fail with error code \((error as NSError).code), message: \(error.localizedDescription)")
    }
}
