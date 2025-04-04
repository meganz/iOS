import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import MEGATest
import XCTest

final class SubscriptionsRepositoryTests: XCTestCase {

    // MARK: - Cancel subscription with reason string
    func testCancelSubscriptionsWithReasonString_successRequest_shouldNotThrowError() async {
        let sut = SubscriptionsRepository(sdk: successMockSdk)
        
        await XCTAsyncAssertNoThrow(
            try await sut.cancelSubscriptions(
                reason: selectedReasonString,
                subscriptionId: subscriptionId,
                canContact: Bool.random()
            )
        )
    }
    
    func testCancelSubscriptionsWithReasonString_failedRequest_shouldThrowGenericError() async {
        let sut = SubscriptionsRepository(sdk: failedMockSdk)
        
        await XCTAsyncAssertThrowsError(
            try await sut.cancelSubscriptions(
                reason: selectedReasonString,
                subscriptionId: subscriptionId,
                canContact: Bool.random()
            )
        ) { errorThrown in
            XCTAssertEqual(errorThrown as? AccountErrorEntity, .generic)
        }
    }
    
    // MARK: - Cancel subscription with reason list
    func testCancelSubscriptionsWithReasonList_successRequest_shouldNotThrowError() async {
        let sut = SubscriptionsRepository(sdk: successMockSdk)
        
        await XCTAsyncAssertNoThrow(
            try await sut.cancelSubscriptions(
                reasonList: selectedReasonList(),
                subscriptionId: subscriptionId,
                canContact: Bool.random()
            )
        )
    }

    func testCancelSubscriptionsWithReasonList_failedRequest_shouldThrowGenericError() async {
        let sut = SubscriptionsRepository(sdk: failedMockSdk)
        
        await XCTAsyncAssertThrowsError(
            try await sut.cancelSubscriptions(
                reasonList: selectedReasonList(),
                subscriptionId: subscriptionId,
                canContact: Bool.random()
            )
        ) { errorThrown in
            XCTAssertEqual(errorThrown as? AccountErrorEntity, .generic)
        }
    }
    
    // MARK: - Helpers
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
    
    private let successMockSdk: MockSdk = MockSdk(requestResult: .success(MockRequest(handle: 1)))
    
    private let failedMockSdk: MockSdk = MockSdk(requestResult: .failure(MockError.failingError))
}
