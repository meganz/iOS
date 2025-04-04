import MEGAAppSDKRepo
import MEGADomain
import MEGASdk

public struct MockPricingProduct {
    public var handle: HandleEntity
    public var proLevel: MEGAAccountType
    public var storageGB: Int
    public var transferGB: Int
    public var months: Int
    public var amount: Int
    public var localPrice: Int
    public var description: String?
    public var iOSID: String?
    
    public init(handle: HandleEntity = .invalidHandle,
                proLevel: MEGAAccountType = .free,
                storageGB: Int = 0,
                transferGB: Int = 0,
                months: Int = 0,
                amount: Int = 0,
                localPrice: Int = 0,
                description: String? = nil,
                iOSID: String? = nil) {
        self.handle = handle
        self.proLevel = proLevel
        self.storageGB = storageGB
        self.transferGB = transferGB
        self.months = months
        self.amount = amount
        self.localPrice = localPrice
        self.description = description
        self.iOSID = iOSID
    }
}

public final class MockMEGAPricing: MEGAPricing {
    private let productList: [MockPricingProduct]?
    
    public init(productList: [MockPricingProduct]?) {
        self.productList = productList
    }
    
    public override var products: Int {
        productList?.count ?? 0
    }

    private func product(at index: Int) -> MockPricingProduct? {
        productList?[safe: index]
    }
    
    public override func handle(atProductIndex index: Int) -> UInt64 {
        product(at: index)?.handle ?? .invalidHandle
    }
    
    public override func proLevel(atProductIndex index: Int) -> MEGAAccountType {
        product(at: index)?.proLevel ?? .free
    }
    
    public override func storageGB(atProductIndex index: Int) -> Int {
        product(at: index)?.storageGB ?? 0
    }
    
    public override func transferGB(atProductIndex index: Int) -> Int {
        product(at: index)?.transferGB ?? 0
    }
    
    public override func months(atProductIndex index: Int) -> Int {
        product(at: index)?.months ?? 0
    }
    
    public override func amount(atProductIndex index: Int) -> Int {
        product(at: index)?.amount ?? 0
    }
    
    public override func localPrice(atProductIndex index: Int) -> Int {
        product(at: index)?.localPrice ?? 0
    }
    
    public override func description(atProductIndex index: Int) -> String? {
        product(at: index)?.description
    }
    
    public override func iOSID(atProductIndex index: Int) -> String? {
        product(at: index)?.iOSID
    }
}
