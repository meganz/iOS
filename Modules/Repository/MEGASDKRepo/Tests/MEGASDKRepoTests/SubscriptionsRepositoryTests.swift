import MEGADomain
import MEGASDKRepo
import MEGASDKRepoMock
import MEGATest
import XCTest

final class SubscriptionsRepositoryTests: XCTestCase {

    func testCancelSubscriptions_successRequest_shouldNotThrowError() async {
        let mockSdk = MockSdk(requestResult: .success(MockRequest(handle: 1)))
        let sut = SubscriptionsRepository(sdk: mockSdk)
        
        await XCTAsyncAssertNoThrow(
            try await sut.cancelSubscriptions(
                reason: "Test reason",
                subscriptionId: "123ABC",
                canContact: Bool.random()
            )
        )
    }
    
    func testCancelSubscriptions_failedRequest_shouldThrowGenericError() async {
        let mockSdk = MockSdk(requestResult: .failure(MockError.failingError))
        let sut = SubscriptionsRepository(sdk: mockSdk)
        
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
