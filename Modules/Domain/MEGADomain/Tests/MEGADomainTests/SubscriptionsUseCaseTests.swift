import MEGADomain
import MEGADomainMock
import MEGATest
import XCTest

final class SubscriptionsUseCaseTests: XCTestCase {
    // MARK: - Cancel subscription with reason string
    
    func testCancelSubscriptionsWithReasonString_successRequest_shouldNotThrowError() async {
        await XCTAsyncAssertNoThrow(
            try await assertCancelSubscriptionWithReasonString(expectedResult: .success)
        )
    }
    
    func testCancelSubscriptionsWithReasonString_failedRequest_shouldThrowGenericError() async {
        let error: AccountErrorEntity = .generic
        
        await XCTAsyncAssertThrowsError(
            try await assertCancelSubscriptionWithReasonString(expectedResult: .failure(error))
        ) { errorThrown in
            XCTAssertEqual(errorThrown as? AccountErrorEntity, error)
        }
    }
    
    // MARK: - Cancel subscription with reason list
    
    func testCancelSubscriptionsWithReasonList_successRequest_shouldNotThrowError() async {
        await XCTAsyncAssertNoThrow(
            try await assertCancelSubscriptionWithReasonList(expectedResult: .success)
        )
    }
    
    func testCancelSubscriptionsWithReasonList_failedRequest_shouldThrowGenericError() async {
        let error: AccountErrorEntity = .generic
        
        await XCTAsyncAssertThrowsError(
            try await assertCancelSubscriptionWithReasonList(expectedResult: .failure(error))
        ) { errorThrown in
            XCTAssertEqual(errorThrown as? AccountErrorEntity, error)
        }
    }
    
    // MARK: - Helpers
    private func makeSUT(requestResult: Result<Void, AccountErrorEntity>) -> SubscriptionsUseCase {
        let mockRepo = MockSubscriptionRepository(requestResult: requestResult)
        return SubscriptionsUseCase(repo: mockRepo)
    }
    
    private func assertCancelSubscriptionWithReasonString(expectedResult: Result<Void, AccountErrorEntity>) async throws {
        let sut = makeSUT(requestResult: expectedResult)
        
        return try await sut.cancelSubscriptions(
            reason: selectedReasonString,
            subscriptionId: subscriptionId,
            canContact: Bool.random()
        )
    }
    
    private func assertCancelSubscriptionWithReasonList(expectedResult: Result<Void, AccountErrorEntity>) async throws {
        let sut = makeSUT(requestResult: expectedResult)
        
        return try await sut.cancelSubscriptions(
            reasonList: selectedReasonList(),
            subscriptionId: subscriptionId,
            canContact: Bool.random()
        )
    }
    
    private let subscriptionId = "123ABC"
    
    private var selectedReasonString: String? {
        Bool.random() ? nil : "Test reason"
    }
    
    private func selectedReasonList() -> [CancelSubscriptionReasonEntity]? {
        let returnNil = Bool.random()
        
        if returnNil { return nil }
        
        return [
            .init(text: "1.b", position: "2.a"),
            .init(text: "2", position: "5"),
            .init(text: "3", position: "7"),
            .init(text: "8 - other reason user input", position: "10")
        ]
    }
}
