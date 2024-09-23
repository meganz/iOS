@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

final class AccountPlanPurchaseUpdatesProviderTests: XCTestCase {
    private var purchase: MockMEGAPurchase!
    private var sut: AccountPlanPurchaseUpdatesProvider!
    
    override func setUp() {
        super.setUp()
        purchase = MockMEGAPurchase()
        sut = AccountPlanPurchaseUpdatesProvider(purchase: purchase)
    }
    
    override func tearDown() {
        purchase = nil
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Purchase
    func testPurchasePlanResultUpdates_shouldAddRequestDelegateAndRemoveWhenTerminated() async {
        let expectation = expectation(description: "Finish purchase plan request")
        let task = startMonitoringPurchaseUpdates(expectation)
        
        // This is necessary for the delegate to be added before the below simulatePurchase get called.
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        XCTAssertTrue(purchase.hasPurchaseDelegate)
        
        purchase.simulatePurchase(result: randomPurchaseResult())
        
        task.cancel()
        
        await fulfillment(of: [expectation], timeout: 1)
        XCTAssertFalse(purchase.hasPurchaseDelegate)
    }
    
    func testPurchasePlanResultUpdates_whenNotTerminated_shouldYieldElements() async {
        let expectation = expectation(description: "Finish purchase plan request")
        let task = startMonitoringPurchaseUpdates(expectation)
        
        // This is necessary for the delegate to be added before the below simulatePurchase get called.
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Trigger new request results before terminating stream. Expected value count.
        purchase.simulatePurchase(result: randomPurchaseResult())
        purchase.simulatePurchase(result: randomPurchaseResult())
        
        task.cancel()
        
        await fulfillment(of: [expectation], timeout: 1)
        let requestValues = await task.value
        
        XCTAssertEqual(requestValues.count, 2)
    }
    
    func testPurchasePlanResultUpdates_whenTerminated_shouldStopYieldingElements() async {
        let expectation = expectation(description: "Finish purchase plan request")
        let task = startMonitoringPurchaseUpdates(expectation)
        
        // This is necessary for the delegate to be added before the below simulateOnRequestFinish get called.
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Trigger new request results before terminating stream. Expected value count.
        purchase.simulatePurchase(result: randomPurchaseResult())
        purchase.simulatePurchase(result: randomPurchaseResult())
        purchase.simulatePurchase(result: randomPurchaseResult())
        
        task.cancel()
        
        // This is necessary for the delegate to be removed before the below simulatePurchase get called.
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Trigger new request results after terminating stream. Should not be received.
        purchase.simulatePurchase(result: randomPurchaseResult())
        
        await fulfillment(of: [expectation], timeout: 1)
        let requestValues = await task.value
        
        XCTAssertEqual(requestValues.count, 3)
    }
    
    func testPurchasePlanResultUpdates_whenSuccessful_shouldYieldCorrectResult() async throws {
        let expectation = expectation(description: "Finish purchase plan request")
        let task = startMonitoringPurchaseUpdates(expectation)
        
        // This is necessary for the delegate to be added before the below simulatePurchase get called.
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Trigger new request results before terminating stream. Expected value count.
        purchase.simulatePurchase(result: .success)
        
        task.cancel()
        
        await fulfillment(of: [expectation], timeout: 1)
        let requestValues = await task.value
        
        XCTAssertEqual(requestValues.count, 1)
        let result = try XCTUnwrap(requestValues.first)
        if case .failure(let error) = result {
            XCTFail("Expected success, but got error \(error).")
        }
    }
    
    func testPurchasePlanResultUpdates_whenFailed_shouldYieldCorrectResult() async throws {
        let expectation = expectation(description: "Finish purchase plan request")
        let task = startMonitoringPurchaseUpdates(expectation)
        
        // This is necessary for the delegate to be added before the below simulatePurchase get called.
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Trigger new request results before terminating stream. Expected value count.
        let expectedError = AccountPlanErrorEntity.random
        purchase.simulatePurchase(result: .failure(expectedError))
        
        task.cancel()
        
        await fulfillment(of: [expectation], timeout: 1)
        let requestValues = await task.value
        
        XCTAssertEqual(requestValues.count, 1)
        let result = try XCTUnwrap(requestValues.first)
        switch result {
        case .success:
            XCTFail("Expected failure, but got success.")
        case .failure(let error):
            XCTAssertEqual(error.errorCode, expectedError.errorCode)
            XCTAssertEqual(error.errorMessage, expectedError.errorMessage)
        }
    }
    
    // MARK: - Restore
    func testRestorePurchaseUpdates_shouldAddRequestDelegateAndRemoveWhenTerminated() async {
        let expectation = expectation(description: "Finish restore subscription request")
        let task = startMonitoringRestoreUpdates(expectation)
        
        // This is necessary for the delegate to be added before the below simulateRestore get called.
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        XCTAssertTrue(purchase.hasRestoreDelegate)
        
        purchase.simulateRestore(status: randomRestoreResult())
        
        task.cancel()
        
        await fulfillment(of: [expectation], timeout: 1)
        XCTAssertFalse(purchase.hasRestoreDelegate)
    }
    
    func testRestorePurchaseUpdates_whenNotTerminated_shouldYieldElements() async {
        let expectation = expectation(description: "Finish restore subscription request")
        let task = startMonitoringRestoreUpdates(expectation)
        
        // This is necessary for the delegate to be added before the below simulateRestore get called.
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Trigger new request results before terminating stream. Expected value count.
        purchase.simulateRestore(status: randomRestoreResult())
        purchase.simulateRestore(status: randomRestoreResult())
        
        task.cancel()
        
        await fulfillment(of: [expectation], timeout: 1)
        let requestValues = await task.value
        
        XCTAssertEqual(requestValues.count, 2)
    }
    
    func testRestorePurchaseUpdates_whenTerminated_shouldStopYieldingElements() async {
        let expectation = expectation(description: "Finish restore subscription request")
        let task = startMonitoringRestoreUpdates(expectation)
        
        // This is necessary for the delegate to be added before the below simulateOnRequestFinish get called.
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Trigger new request results before terminating stream. Expected value count.
        purchase.simulateRestore(status: randomRestoreResult())
        purchase.simulateRestore(status: randomRestoreResult())
        purchase.simulateRestore(status: randomRestoreResult())
        
        task.cancel()
        
        // Trigger new request results after terminating stream. Should not be received.
        purchase.simulateRestore(status: .success)
        
        await fulfillment(of: [expectation], timeout: 1)
        let requestValues = await task.value
        
        XCTAssertEqual(requestValues.count, 3)
    }
    
    private func assertRestorePurchaseUpdates(
        expectedResult: RestorePurchaseStateEntity,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        let expectation = expectation(description: "Finish restore subscription request")
        let task = startMonitoringRestoreUpdates(expectation)
        
        // This is necessary for the delegate to be added before the below simulateRestore get called.
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Trigger new request results before terminating stream. Expected value count.
        purchase.simulateRestore(status: expectedResult)
        
        task.cancel()
        
        await fulfillment(of: [expectation], timeout: 1)
        let requestValues = await task.value
        
        XCTAssertEqual(requestValues.count, 1, file: file, line: line)
        let result = try XCTUnwrap(requestValues.first)
        XCTAssertEqual(result, expectedResult, file: file, line: line)
    }
    
    func testRestorePurchaseUpdates_whenSuccessful_shouldYieldCorrectResult() async throws {
        try await assertRestorePurchaseUpdates(expectedResult: .success)
    }
    
    func testRestorePurchaseUpdates_whenIncomplete_shouldYieldCorrectResult() async throws {
        try await assertRestorePurchaseUpdates(expectedResult: .incomplete)
    }
    
    func testRestorePurchaseUpdates_whenFailed_shouldYieldCorrectResult() async throws {
        try await assertRestorePurchaseUpdates(expectedResult: .failed(AccountPlanErrorEntity.random))
    }
    
    // MARK: - Helpers
    private func startMonitoringPurchaseUpdatess(_ expectationToFulfill: XCTestExpectation) async -> [Result<Void, AccountPlanErrorEntity>] {
        var results: [Result<Void, AccountPlanErrorEntity>] = []
        for await requestResult in sut.purchasePlanResultUpdates {
            results.append(requestResult)
        }
        expectationToFulfill.fulfill()
        return results
    }
    
    private func startMonitoringPurchaseUpdates(_ expectationToFulfill: XCTestExpectation) -> Task<[Result<Void, AccountPlanErrorEntity>], Never> {
        Task { [sut] in
            guard let sut else { return [] }
            var results: [Result<Void, AccountPlanErrorEntity>] = []
            for await requestResult in sut.purchasePlanResultUpdates {
                results.append(requestResult)
            }
            expectationToFulfill.fulfill()
            return results
        }
    }
    
    private func startMonitoringRestoreUpdates(_ expectationToFulfill: XCTestExpectation) -> Task<[RestorePurchaseStateEntity], Never> {
        Task { [sut] in
            guard let sut else { return [] }
            var results: [RestorePurchaseStateEntity] = []
            for await requestResult in sut.restorePurchaseUpdates {
                results.append(requestResult)
            }
            expectationToFulfill.fulfill()
            return results
        }
    }

    private func randomPurchaseResult() -> Result<Void, AccountPlanErrorEntity> {
        let results: [Result<Void, AccountPlanErrorEntity>] = [.success, .failure(AccountPlanErrorEntity.random)]
        return results.randomElement() ?? .success
    }
    
    private func randomRestoreResult() -> RestorePurchaseStateEntity {
        let status: [RestorePurchaseStateEntity] = [.success, .incomplete, .failed(AccountPlanErrorEntity.random)]
        return status.randomElement() ?? .success
    }
}
