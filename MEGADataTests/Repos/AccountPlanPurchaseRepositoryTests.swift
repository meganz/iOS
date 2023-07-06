import Combine
@testable import MEGA
import MEGADomain
import XCTest

final class AccountPlanPurchaseRepositoryTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    
    func testAccountPlanProducts_monthly() async {
        let products = [MockSKProduct(identifier: "pro1.oneMonth", price: "1", priceLocale: Locale.current),
                        MockSKProduct(identifier: "pro2.oneMonth", price: "1", priceLocale: Locale.current),
                        MockSKProduct(identifier: "pro3.oneMonth", price: "1", priceLocale: Locale.current),
                        MockSKProduct(identifier: "lite.oneMonth", price: "1", priceLocale: Locale.current)]
        let expectedResult = [AccountPlanEntity(type: .proI, term: .monthly),
                              AccountPlanEntity(type: .proII, term: .monthly),
                              AccountPlanEntity(type: .proIII, term: .monthly),
                              AccountPlanEntity(type: .lite, term: .monthly)]
        
        let mockPurchase = MockMEGAPurchase(productPlans: products)
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase)
        let plans = await sut.accountPlanProducts()
        XCTAssertEqual(plans, expectedResult)
    }
    
    func testAccountPlanProducts_yearly() async {
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
        let plans = await sut.accountPlanProducts()
        XCTAssertEqual(plans, expectedResult)
    }
    
    func testRestorePurchase_addDelegate_delegateShouldExist() async {
        let mockPurchase = MockMEGAPurchase()
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase)
        await sut.registerRestoreDelegate()
        XCTAssertTrue(mockPurchase.hasRestoreDelegate)
    }
    
    func testRestorePurchase_removeDelegate_delegateShouldNotExist() async {
        let mockPurchase = MockMEGAPurchase()
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase)
        await sut.registerRestoreDelegate()
        
        await sut.deRegisterRestoreDelegate()
        XCTAssertFalse(mockPurchase.hasRestoreDelegate)
    }
    
    func testRestorePurchaseCalled_shouldReturnTrue() async {
        let mockPurchase = MockMEGAPurchase()
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase)
        await sut.restorePurchase()
        XCTAssertTrue(mockPurchase.restorePurchaseCalled == 1)
    }
    
    func testRestorePublisher_successfulRestorePublisher_shouldSendToPublisher() {
        let mockPurchase = MockMEGAPurchase()
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase)
        
        let exp = expectation(description: "Should receive signal from successfulRestorePublisher")
        sut.successfulRestorePublisher
            .sink {
                exp.fulfill()
            }.store(in: &subscriptions)
        sut.successfulRestore(mockPurchase)
        wait(for: [exp], timeout: 1)
    }
    
    func testRestorePublisher_incompleteRestorePublisher_shouldSendToPublisher() {
        let mockPurchase = MockMEGAPurchase()
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase)
        
        let exp = expectation(description: "Should receive signal from incompleteRestorePublisher")
        sut.incompleteRestorePublisher
            .sink {
                exp.fulfill()
            }.store(in: &subscriptions)
        sut.incompleteRestore()
        wait(for: [exp], timeout: 1)
    }
    
    func testRestorePublisher_failedRestorePublisher_shouldSendToPublisher() {
        let mockPurchase = MockMEGAPurchase()
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase)
        
        let exp = expectation(description: "Should receive signal from failedRestorePublisher")
        let expectedError = AccountPlanErrorEntity(errorCode: 1, errorMessage: "Test Error")
        sut.failedRestorePublisher
            .sink { errorEntity in
                XCTAssertEqual(errorEntity.errorCode, expectedError.errorCode)
                XCTAssertEqual(errorEntity.errorMessage, expectedError.errorMessage)
                exp.fulfill()
            }.store(in: &subscriptions)
        sut.failedRestore(expectedError.errorCode, message: expectedError.errorMessage)
        wait(for: [exp], timeout: 1)
    }
}
