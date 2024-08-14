import MEGADomain
import MEGADomainMock
import MEGATest
import XCTest

final class SubscriptionsUseCaseTests: XCTestCase {

    func testCancelSubscriptions_successRequest_shouldNotThrowError() async {
        let mockRepo = MockSubscriptionRepository(requestResult: .success)
        let sut = SubscriptionsUsecase(repo: mockRepo)
        
        await XCTAsyncAssertNoThrow(
            try await sut.cancelSubscriptions(
                reason: "Test reason",
                subscriptionId: "123ABC",
                canContact: Bool.random()
            )
        )
    }
    
    func testCancelSubscriptions_failedRequest_shouldThrowGenericError() async {
        let mockRepo = MockSubscriptionRepository(requestResult: .failure(.generic))
        let sut = SubscriptionsUsecase(repo: mockRepo)
        
        await XCTAsyncAssertThrowsError(
            try await sut.cancelSubscriptions(
                reason: "Test reason",
                subscriptionId: "123ABC",
                canContact: Bool.random()
            )
        ) { errorThrown in
            XCTAssertEqual(errorThrown as? AccountErrorEntity, .generic)
        }
    }
}
