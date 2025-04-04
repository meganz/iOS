import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import XCTest

final class MEGAPricingAdditionsTests: XCTestCase {
    private let proPlans = [MockPricingProduct(proLevel: .lite, storageGB: 400),
                            MockPricingProduct(proLevel: .proI, storageGB: 2048),
                            MockPricingProduct(proLevel: .proII, storageGB: 8192),
                            MockPricingProduct(proLevel: .proIII, storageGB: 16384)]
    
    private var randomProPlan: MockPricingProduct {
        proPlans.randomElement() ?? MockPricingProduct(proLevel: .proIII, storageGB: 16384)
    }
    
    private var randomAccountType: AccountTypeEntity {
        let types: [AccountTypeEntity] = [.lite, .proI, .proII, .proIII]
        return types.randomElement() ?? .proIII
    }
    
    func testProductStorageOfAccountType_noProducts_shouldReturnZero() {
        let pricing = MockMEGAPricing(productList: nil)
        let storageGB = pricing.productStorageGB(ofAccountType: randomAccountType)
        XCTAssertEqual(storageGB, 0)
    }
    
    func testProductStorageOfAccountType_withEmptyProducts_shouldReturnZero() {
        let pricing = MockMEGAPricing(productList: [])
        let storageGB = pricing.productStorageGB(ofAccountType: randomAccountType)
        XCTAssertEqual(storageGB, 0)
    }
    
    func testProductStorageOfAccountType_withValidProducts_shouldReturnCorrectValue() {
        let expectedProPlan = randomProPlan
        
        let pricing = MockMEGAPricing(productList: proPlans)
        let storageGB = pricing.productStorageGB(ofAccountType: expectedProPlan.proLevel.toAccountTypeEntity())
        
        XCTAssertEqual(storageGB, expectedProPlan.storageGB)
    }
}
