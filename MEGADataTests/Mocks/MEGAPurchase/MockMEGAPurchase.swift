
final class MockMEGAPurchase: MEGAPurchase {
    
    init(productPlans: [MockSKProduct] = []) {
        super.init()
        
        products = NSMutableArray(array: productPlans)
    }
}
