import MEGADomain
import MEGADomainMock
import MEGATest
import XCTest

final class SubscriptionsUseCaseTests: XCTestCase {
    private func makeSUT(requestResult: Result<Void, AccountErrorEntity>) -> SubscriptionsUseCase {
        let mockRepo = MockSubscriptionRepository(requestResult: requestResult)
        return SubscriptionsUseCase(repo: mockRepo)
    }
    
    private func testCancelSubscription(expectedResult: Result<Void, AccountErrorEntity>) async throws {
        let sut = makeSUT(requestResult: expectedResult)
        
        return try await sut.cancelSubscriptions(
            reason: "Test reason",
            subscriptionId: "123ABC",
            canContact: Bool.random()
        )
    }

    func testCancelSubscriptions_successRequest_shouldNotThrowError() async {
        await XCTAsyncAssertNoThrow(
            try await testCancelSubscription(expectedResult: .success)
        )
    }
    
    func testCancelSubscriptions_failedRequest_shouldThrowGenericError() async {
        let error: AccountErrorEntity = .generic
        
        await XCTAsyncAssertThrowsError(
            try await testCancelSubscription(expectedResult: .failure(error))
        ) { errorThrown in
            XCTAssertEqual(errorThrown as? AccountErrorEntity, error)
        }
    }
}
