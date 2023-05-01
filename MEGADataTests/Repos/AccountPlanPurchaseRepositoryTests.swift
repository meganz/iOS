import XCTest
import MEGADomain
@testable import MEGA

final class AccountPlanPurchaseRepositoryTests: XCTestCase {

    func testAccountPlanProducts_monthly() {
        let products = [MockSKProduct(identifier: "pro1.oneMonth", price: "1", priceLocale: Locale.current),
                        MockSKProduct(identifier: "pro2.oneMonth", price: "1", priceLocale: Locale.current),
                        MockSKProduct(identifier: "pro3.oneMonth", price: "1", priceLocale: Locale.current),
                        MockSKProduct(identifier: "lite.oneMonth", price: "1", priceLocale: Locale.current),]
        let expectedResult = [AccountPlanEntity(type: .proI, term: .monthly),
                              AccountPlanEntity(type: .proII, term: .monthly),
                              AccountPlanEntity(type: .proIII, term: .monthly),
                              AccountPlanEntity(type: .lite, term: .monthly)]
        
        let mockPurchase = MockMEGAPurchase(productPlans: products)
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase)
        XCTAssertEqual(sut.accountPlanProducts(), expectedResult)
    }
    
    func testAccountPlanProducts_yearly() {
        let products = [MockSKProduct(identifier: "pro1.oneYear", price: "1", priceLocale: Locale.current),
                        MockSKProduct(identifier: "pro2.oneYear", price: "1", priceLocale: Locale.current),
                        MockSKProduct(identifier: "pro3.oneYear", price: "1", priceLocale: Locale.current),
                        MockSKProduct(identifier: "lite.oneYear", price: "1", priceLocale: Locale.current)]
        let expectedResult = [AccountPlanEntity(type: .proI, term: .yearly),
                              AccountPlanEntity(type: .proII, term: .yearly),
                              AccountPlanEntity(type: .proIII, term: .yearly),
                              AccountPlanEntity(type: .lite, term: .yearly)]
        
        let mockPurchase = MockMEGAPurchase(productPlans: products)
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase)
        XCTAssertEqual(sut.accountPlanProducts(), expectedResult)
    }
}
