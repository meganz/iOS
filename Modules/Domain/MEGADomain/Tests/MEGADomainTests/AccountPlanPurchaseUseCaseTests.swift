import MEGADomain
import MEGADomainMock
import MEGASwift
import XCTest

final class AccountPlanPurchaseUseCaseTests: XCTestCase {
    // MARK: - Helpers
    private func makeSUT(
        plans: [PlanEntity] = [],
        purchasePlanResultUpdate: Result<Void, AccountPlanErrorEntity> = .success,
        restorePurchaseUpdate: RestorePurchaseStateEntity = .success
    ) -> AccountPlanPurchaseUseCase<MockAccountPlanPurchaseRepository> {
        let mockRepo = MockAccountPlanPurchaseRepository(
            plans: plans,
            purchasePlanResultUpdates: SingleItemAsyncSequence(item: purchasePlanResultUpdate).eraseToAnyAsyncSequence(),
            restorePurchaseUpdates: SingleItemAsyncSequence(item: restorePurchaseUpdate).eraseToAnyAsyncSequence()
        )
        return AccountPlanPurchaseUseCase(repository: mockRepo)
    }
    
    private var monthlyPlans: [PlanEntity] {
        [PlanEntity(type: .proI, subscriptionCycle: .monthly),
         PlanEntity(type: .proII, subscriptionCycle: .monthly),
         PlanEntity(type: .proIII, subscriptionCycle: .monthly),
         PlanEntity(type: .lite, subscriptionCycle: .monthly)]
    }
    
    private var yearlyPlans: [PlanEntity] {
        [PlanEntity(type: .proI, subscriptionCycle: .yearly),
         PlanEntity(type: .proII, subscriptionCycle: .yearly),
         PlanEntity(type: .proIII, subscriptionCycle: .yearly),
         PlanEntity(type: .lite, subscriptionCycle: .yearly)]
    }
    
    private var allPlans: [PlanEntity] {
        monthlyPlans + yearlyPlans
    }
    
    // MARK: - Plans
    func testAccountPlanProducts_monthly() async {
        let sut = makeSUT(plans: monthlyPlans)
        let products = await sut.accountPlanProducts()
        XCTAssertTrue(products == monthlyPlans)
    }
    
    func testAccountPlanProducts_yearly() async {
        let sut = makeSUT(plans: yearlyPlans)
        let products = await sut.accountPlanProducts()
        XCTAssertTrue(products == yearlyPlans)
    }
    
    func testAccountPlanProducts_monthlyAndYearly() async {
        let sut = makeSUT(plans: allPlans)
        let products = await sut.accountPlanProducts()
        XCTAssertTrue(products == allPlans)
    }
    
    // MARK: - Purchase
    func testPurchasePlanResultUpdates_whenSuccessful_shouldReturnCorrectResult() async {
        let sut = makeSUT(purchasePlanResultUpdate: .success)
        var iterator = sut.purchasePlanResultUpdates.makeAsyncIterator()
        
        let result = await iterator.next()
        await XCTAsyncAssertNoThrow(try result?.get())
    }
    
    func testPurchasePlanResultUpdates_whenFailed_shouldReturnCorrectResult() async throws {
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
    
    // MARK: - Restore
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
    
    func testRestorePurchaseUpdates_whenSuccessful_shouldReturnCorrectResult() async {
        await assertRestorePurchaseUpdates(expectedResult: .success)
    }
    
    func testRestorePurchaseUpdates_whenIncomplete_shouldReturnCorrectResult() async {
        await assertRestorePurchaseUpdates(expectedResult: .incomplete)
    }
    
    func testRestorePurchaseUpdates_whenFailed_shouldReturnCorrectResult() async {
        await assertRestorePurchaseUpdates(expectedResult: .failed(AccountPlanErrorEntity.random))
    }
}
