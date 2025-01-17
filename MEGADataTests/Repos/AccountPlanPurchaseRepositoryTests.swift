import Combine
@testable import MEGA
import MEGADomain
import MEGASDKRepoMock
import XCTest

final class AccountPlanPurchaseRepositoryTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    
    // MARK: Plans
    func testAccountPlanProducts_monthly() async {
        let products = [MockSKProduct(identifier: "pro1.oneMonth", price: "1", priceLocale: Locale.current),
                        MockSKProduct(identifier: "pro2.oneMonth", price: "1", priceLocale: Locale.current),
                        MockSKProduct(identifier: "pro3.oneMonth", price: "1", priceLocale: Locale.current),
                        MockSKProduct(identifier: "lite.oneMonth", price: "1", priceLocale: Locale.current)]
        let expectedResult = [PlanEntity(type: .proI, subscriptionCycle: .monthly),
                              PlanEntity(type: .proII, subscriptionCycle: .monthly),
                              PlanEntity(type: .proIII, subscriptionCycle: .monthly),
                              PlanEntity(type: .lite, subscriptionCycle: .monthly)]
        
        let mockPurchase = MockMEGAPurchase(productPlans: products)
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase, sdk: MockSdk())
        let plans = await sut.accountPlanProducts()
        XCTAssertEqual(plans, expectedResult)
    }
    
    func testAccountPlanProducts_yearly() async {
        let products = [MockSKProduct(identifier: "pro1.oneYear", price: "1", priceLocale: Locale.current),
                        MockSKProduct(identifier: "pro2.oneYear", price: "1", priceLocale: Locale.current),
                        MockSKProduct(identifier: "pro3.oneYear", price: "1", priceLocale: Locale.current),
                        MockSKProduct(identifier: "lite.oneYear", price: "1", priceLocale: Locale.current)]
        let expectedResult = [PlanEntity(type: .proI, subscriptionCycle: .yearly),
                              PlanEntity(type: .proII, subscriptionCycle: .yearly),
                              PlanEntity(type: .proIII, subscriptionCycle: .yearly),
                              PlanEntity(type: .lite, subscriptionCycle: .yearly)]
        
        let mockPurchase = MockMEGAPurchase(productPlans: products)
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase, sdk: MockSdk())
        let plans = await sut.accountPlanProducts()
        XCTAssertEqual(plans, expectedResult)
    }
    
    // MARK: Restore purchase
    func testRestorePurchase_addDelegate_delegateShouldExist() async {
        let mockPurchase = MockMEGAPurchase()
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase, sdk: MockSdk())
        await sut.registerRestoreDelegate()
        XCTAssertTrue(mockPurchase.hasRestoreDelegate)
    }
    
    func testRestorePurchase_removeDelegate_delegateShouldNotExist() async {
        let mockPurchase = MockMEGAPurchase()
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase, sdk: MockSdk())
        await sut.registerRestoreDelegate()
        
        await sut.deRegisterRestoreDelegate()
        XCTAssertFalse(mockPurchase.hasRestoreDelegate)
    }
    
    func testRestorePurchaseCalled_shouldReturnTrue() async {
        let mockPurchase = MockMEGAPurchase()
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase, sdk: MockSdk())
        sut.restorePurchase()
        XCTAssertTrue(mockPurchase.restorePurchaseCalled == 1)
    }
    
    func testRestorePublisher_successfulRestorePublisher_shouldSendToPublisher() {
        let mockPurchase = MockMEGAPurchase()
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase, sdk: MockSdk())
        
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
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase, sdk: MockSdk())
        
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
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase, sdk: MockSdk())
        
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
    
    // MARK: Purchase plan
    func testPurchasePlan_addDelegate_delegateShouldExist() async {
        let mockPurchase = MockMEGAPurchase()
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase, sdk: MockSdk())
        await sut.registerPurchaseDelegate()
        XCTAssertTrue(mockPurchase.hasPurchaseDelegate)
    }
    
    func testPurchasePlan_removeDelegate_delegateShouldNotExist() async {
        let mockPurchase = MockMEGAPurchase()
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase, sdk: MockSdk())
        await sut.registerPurchaseDelegate()
        
        await sut.deRegisterPurchaseDelegate()
        XCTAssertFalse(mockPurchase.hasPurchaseDelegate)
    }
    
    func testPurchasePublisher_successPurchase_shouldSendToPublisher() {
        let mockPurchase = MockMEGAPurchase()
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase, sdk: MockSdk())
        
        let exp = expectation(description: "Should receive success purchase result")
        sut.purchasePlanResultPublisher
            .sink { result in
                if case .failure = result {
                    XCTFail("Request error is not expected.")
                }
                exp.fulfill()
            }.store(in: &subscriptions)
        
        sut.successfulPurchase(mockPurchase)
        wait(for: [exp], timeout: 1)
    }
    
    func testPurchasePublisher_failedPurchase_shouldSendToPublisher() {
        let mockPurchase = MockMEGAPurchase()
        let sut = AccountPlanPurchaseRepository(purchase: mockPurchase, sdk: MockSdk())
        let expectedError = AccountPlanErrorEntity(errorCode: 1, errorMessage: "TestError")
        
        let exp = expectation(description: "Should receive failed purchase result")
        sut.purchasePlanResultPublisher
            .sink { result in
                switch result {
                case .success:
                    XCTFail("Expecting an error but got a success.")
                case .failure(let error):
                    XCTAssertEqual(error.errorCode, expectedError.errorCode)
                    XCTAssertEqual(error.errorMessage, expectedError.errorMessage)
                }
                exp.fulfill()
            }.store(in: &subscriptions)
        
        sut.failedPurchase(expectedError.errorCode, message: expectedError.errorMessage)
        wait(for: [exp], timeout: 1)
    }
    
    // MARK: Submit receipt
    func testSubmitReceiptPublisher_failedResult_shouldSendToPublisher() {
        let sut = AccountPlanPurchaseRepository(purchase: MockMEGAPurchase(), sdk: MockSdk())
        let expectedError = AccountPlanErrorEntity(errorCode: -11, errorMessage: nil)
        
        let exp = expectation(description: "Should receive failed submit receipt result")
        sut.submitReceiptResultPublisher
            .sink { result in
                switch result {
                case .success:
                    XCTFail("Expecting an error but got a success.")
                case .failure(let error):
                    XCTAssertEqual(error.errorCode, expectedError.errorCode)
                }
                exp.fulfill()
            }.store(in: &subscriptions)
        
        sut.failedSubmitReceipt(expectedError.errorCode)
        wait(for: [exp], timeout: 1)
    }
}
