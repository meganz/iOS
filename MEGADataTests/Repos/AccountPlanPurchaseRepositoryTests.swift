@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGASDKRepoMock
import MEGASwift
import MEGATest
import XCTest

final class AccountPlanPurchaseRepositoryTests: XCTestCase {
    
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
        let sut = makeSUT(purchase: mockPurchase)
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
        let sut = makeSUT(purchase: mockPurchase)
        let plans = await sut.accountPlanProducts()
        XCTAssertEqual(plans, expectedResult)
    }
    
    // MARK: Purchase
    func testPurchasePlanResultUpdates_whenSuccessful_shouldYieldCorrectResult() async {
        let sut = makeSUT(purchasePlanResultUpdate: .success)
        var iterator = sut.purchasePlanResultUpdates.makeAsyncIterator()
        
        let result = await iterator.next()
        await XCTAsyncAssertNoThrow(try result?.get())
    }
    
    func testPurchasePlanResultUpdates_whenFailed_shouldYieldCorrectResult() async throws {
        let expectedError = AccountPlanErrorEntity.random
        let sut = makeSUT(purchasePlanResultUpdate: .failure(expectedError))
        var iterator = sut.purchasePlanResultUpdates.makeAsyncIterator()
        
        let result = await iterator.next()
        let purchaseResult = try XCTUnwrap(result)
        switch purchaseResult {
        case .success:
            XCTFail("Expected failure, but got success.")
        case .failure(let error):
            XCTAssertEqual(error.errorCode, expectedError.errorCode)
            XCTAssertEqual(error.errorMessage, expectedError.errorMessage)
        }
    }
    
    // MARK: Restore
    private func assertRestorePurchaseUpdates(
        expectedResult: RestorePurchaseStateEntity,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        let sut = makeSUT(restorePurchaseUpdate: expectedResult)
        var iterator = sut.restorePurchaseUpdates.makeAsyncIterator()
        let result = await iterator.next()
        XCTAssertEqual(result, expectedResult)
    }
    
    func testRestorePurchaseUpdates_whenSuccessful_shouldYieldCorrectResult() async {
        await assertRestorePurchaseUpdates(expectedResult: .success)
    }
    
    func testRestorePurchaseUpdates_whenIncomplete_shouldYieldCorrectResult() async {
        await assertRestorePurchaseUpdates(expectedResult: .incomplete)
    }
    
    func testRestorePurchaseUpdates_whenFailed_shouldYieldCorrectResult() async {
        await assertRestorePurchaseUpdates(expectedResult: .failed(AccountPlanErrorEntity.random))
    }

    // MARK: - Helper
    func makeSUT(
        purchase: MockMEGAPurchase = MockMEGAPurchase(),
        purchasePlanResultUpdate: Result<Void, AccountPlanErrorEntity> = .success,
        restorePurchaseUpdate: RestorePurchaseStateEntity = .success,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> AccountPlanPurchaseRepository {
        let mockPurchaseUpdatesProvider = MockAccountPlanPurchaseUpdatesProvider(
            purchasePlanResultUpdates: SingleItemAsyncSequence(item: purchasePlanResultUpdate).eraseToAnyAsyncSequence(),
            restorePurchaseUpdates: SingleItemAsyncSequence(item: restorePurchaseUpdate).eraseToAnyAsyncSequence()
        )
        let sut = AccountPlanPurchaseRepository(
            purchase: purchase,
            purchaseUpdatesProvider: mockPurchaseUpdatesProvider
        )
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
}
