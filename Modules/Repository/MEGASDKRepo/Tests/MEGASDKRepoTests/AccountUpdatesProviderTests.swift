import MEGADomain
import MEGASDKRepo
import MEGASDKRepoMock
import XCTest

final class AccountUpdatesProviderTests: XCTestCase {
    private var sdk: MockSdk!
    private var sut: AccountUpdatesProvider!
    
    override func setUp() {
        super.setUp()
        sdk = MockSdk(shouldListGlobalDelegates: true)
        sut = AccountUpdatesProvider(sdk: sdk)
    }
    
    override func tearDown() {
        sdk = nil
        sut = nil
        super.tearDown()
    }
    
    // MARK: - onAccountRequestFinish
    func testAccountUpdates_onAccountRequestFinish_shouldAddRequestDelegateAndRemoveWhenTerminated() async {
        let expectation = expectation(description: "Finish account request")
        let task = startMonitoringRequestFinishUpdates(expectation)
        
        // This is necessary for the delegate to be added before the below simulateOnRequestFinish get called.
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        XCTAssertTrue(sdk.hasRequestDelegate)
        
        sdk.simulateOnRequestFinish(MockRequest(handle: 1), error: MockError(errorType: .apiOk))
        
        task.cancel()
        
        await fulfillment(of: [expectation], timeout: 1)
        XCTAssertFalse(sdk.hasRequestDelegate)
    }
    
    func testAccountUpdates_onAccountRequestFinish_whenNotTerminated_shouldYieldElements() async {
        let expectation = expectation(description: "Finish account request")
        let task = startMonitoringRequestFinishUpdates(expectation)
        
        // This is necessary for the delegate to be added before the below simulateOnRequestFinish get called.
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Trigger new request results before terminating stream. Expected value count.
        sdk.simulateOnRequestFinish(MockRequest(handle: 1), error: MockError(errorType: .apiOk))
        sdk.simulateOnRequestFinish(MockRequest(handle: 2), error: MockError(errorType: .apiOk))
        
        task.cancel()
        
        await fulfillment(of: [expectation], timeout: 1)
        let requestValues = await task.value
        
        XCTAssertEqual(requestValues.count, 2)
    }
    
    func testAccountUpdates_onAccountRequestFinish_whenTerminated_shouldStopYieldingElements() async {
        let expectation = expectation(description: "Finish account request")
        let task = startMonitoringRequestFinishUpdates(expectation)
        
        // This is necessary for the delegate to be added before the below simulateOnRequestFinish get called.
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Trigger new request results before terminating stream. Expected value count.
        sdk.simulateOnRequestFinish(MockRequest(handle: 1), error: MockError(errorType: .apiOk))
        sdk.simulateOnRequestFinish(MockRequest(handle: 2), error: MockError(errorType: .apiOk))
        sdk.simulateOnRequestFinish(MockRequest(handle: 3), error: MockError(errorType: .apiOk))
        
        task.cancel()
        
        // This is necessary for the delegate to be removed before the below simulateOnRequestFinish get called.
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Trigger new request results after terminating stream. Should not be received.
        sdk.simulateOnRequestFinish(MockRequest(handle: 4), error: MockError(errorType: .apiOk))
        
        await fulfillment(of: [expectation], timeout: 1)
        let requestValues = await task.value
        
        XCTAssertEqual(requestValues.count, 3)
    }
    
    // MARK: - onUserAlertsUpdates
    
    func testAccountUpdates_onUserAlertsUpdates_shouldAddRequestDelegateAndRemoveWhenTerminated() async {
        let expectation = expectation(description: "Finish onUserAlertsUpdates")
        let task = startMonitoringUserAlertsUpdates(expectation)
        
        // This is necessary for the delegate to be added before the below simulateOnUserAlertsUpdate get called.
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        XCTAssertTrue(sdk.hasGlobalDelegate)
        
        sdk.simulateOnUserAlertsUpdate(MockUserAlertList(alerts: [MockUserAlert(identifier: 1), MockUserAlert(identifier: 2)]))
        
        task.cancel()
        await fulfillment(of: [expectation], timeout: 1)
        XCTAssertFalse(sdk.hasGlobalDelegate)
    }
    
    func testAccountUpdates_onUserAlertsUpdates_whenNotTerminated_shouldYieldElements() async {
        let expectation = expectation(description: "Finish onUserAlertsUpdates")
        let task = startMonitoringUserAlertsUpdates(expectation)
        
        // This is necessary for the delegate to be added before the below simulateOnUserAlertsUpdate get called.
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Trigger new alerts before terminating stream. Expected values from the last trigger.
        sdk.simulateOnUserAlertsUpdate(MockUserAlertList(alerts: [MockUserAlert(identifier: 1), MockUserAlert(identifier: 2)]))
        sdk.simulateOnUserAlertsUpdate(MockUserAlertList(alerts: [MockUserAlert(identifier: 3), MockUserAlert(identifier: 4)]))
        sdk.simulateOnUserAlertsUpdate(MockUserAlertList(alerts: [MockUserAlert(identifier: 5), MockUserAlert(identifier: 6)]))
        
        task.cancel()
        await fulfillment(of: [expectation], timeout: 1)
        
        let values = await task.value
        XCTAssertEqual(values.map(\.identifier), [5, 6])
    }
    
    func testAccountUpdates_onUserAlertsUpdates_whenTerminated_shouldStopYieldingElements() async {
        let expectation = expectation(description: "Finish onUserAlertsUpdates")
        let task = startMonitoringUserAlertsUpdates(expectation)
        
        // This is necessary for the delegate to be added before the below simulateOnUserAlertsUpdate get called.
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Trigger new alerts before terminating stream. Expected values.
        sdk.simulateOnUserAlertsUpdate(MockUserAlertList(alerts: [MockUserAlert(identifier: 1), MockUserAlert(identifier: 2)]))
        
        task.cancel()
        
        // This is necessary for the delegate to be removed before the below simulateOnUserAlertsUpdate get called.
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Trigger new alerts after terminating stream. Should not be received.
        sdk.simulateOnUserAlertsUpdate(MockUserAlertList(alerts: [MockUserAlert(identifier: 3), MockUserAlert(identifier: 4)]))
        
        await fulfillment(of: [expectation], timeout: 1)
        
        let values = await task.value
        XCTAssertEqual(values.map(\.identifier), [1, 2])
    }
    
    // MARK: - onContactRequestsUpdate
    func testAccountUpdates_onContactRequestsUpdates_shouldAddRequestDelegateAndRemoveWhenTerminated() async {
        let expectation = expectation(description: "Finish onContactRequestsUpdate")
        let task = startMonitoringContactRequestsUpdates(expectation)
        
        // This is necessary for the delegate to be added before the below simulateOnContactRequestsUpdate get called.
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        XCTAssertTrue(sdk.hasGlobalDelegate)
        
        // Trigger new contact request before terminating stream. Expected values.
        sdk.simulateOnContactRequestsUpdate(MockContactRequestList(
            contactRequests: [MockContactRequest(targetEmail: "test1@test.com"),
                              MockContactRequest(targetEmail: "test2@test.com")])
        )
        
        task.cancel()
        await fulfillment(of: [expectation], timeout: 1)
        XCTAssertFalse(sdk.hasGlobalDelegate)
    }
    
    func testAccountUpdates_onContactRequestsUpdates_whenNotTerminated_shouldYieldElements() async {
        let expectation = expectation(description: "Finish onContactRequestsUpdate")
        let task = startMonitoringContactRequestsUpdates(expectation)
        
        // This is necessary for the delegate to be added before the below simulateOnUserAlertsUpdate get called.
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Trigger new contact request before terminating stream. Expected values.
        sdk.simulateOnContactRequestsUpdate(MockContactRequestList(
            contactRequests: [MockContactRequest(targetEmail: "test1@test.com"),
                              MockContactRequest(targetEmail: "test2@test.com")])
        )
        
        task.cancel()
        await fulfillment(of: [expectation], timeout: 1)
        
        let values = await task.value
        XCTAssertEqual(values.map(\.targetEmail), ["test1@test.com", "test2@test.com"])
    }
    
    func testAccountUpdates_onContactRequestsUpdate_whenTerminated_shouldStopYieldingElements() async {
        let expectation = expectation(description: "Finish onContactRequestsUpdate")
        let task = startMonitoringContactRequestsUpdates(expectation)
        
        // This is necessary for the delegate to be added before the below simulateOnUserAlertsUpdate get called.
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Trigger new contact request before terminating stream. Expected values.
        sdk.simulateOnContactRequestsUpdate(MockContactRequestList(
            contactRequests: [MockContactRequest(targetEmail: "test1@test.com"),
                              MockContactRequest(targetEmail: "test2@test.com")])
        )
        
        task.cancel()
        
        // This is necessary for the delegate to be added before the below simulateOnContactRequestsUpdate get called.
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Trigger new contact request after terminating stream. Should not be received.
        sdk.simulateOnContactRequestsUpdate(MockContactRequestList(
            contactRequests: [MockContactRequest(targetEmail: "test3@test.com")])
        )
        
        await fulfillment(of: [expectation], timeout: 1)
        
        let values = await task.value
        XCTAssertEqual(values.map(\.targetEmail), ["test1@test.com", "test2@test.com"])
    }
    
    // MARK: - Helpers
    
    private func startMonitoringRequestFinishUpdates(_ expectationToFulfill: XCTestExpectation) -> Task<[Result<AccountRequestEntity, any Error>], Never> {
        Task { [sut] in
            guard let sut else { return [] }
            var results: [Result<AccountRequestEntity, any Error>] = []
            for await requestResult in sut.onAccountRequestFinish {
                results.append(requestResult)
            }
            expectationToFulfill.fulfill()
            return results
        }
    }
    
    private func startMonitoringUserAlertsUpdates(_ expectationToFulfill: XCTestExpectation) -> Task<[UserAlertEntity], Never> {
        Task { [sut] in
            guard let sut else { return [] }
            var userAlerts: [UserAlertEntity] = []
            for await updatedAlerts in sut.onUserAlertsUpdates {
                userAlerts = updatedAlerts
            }
            expectationToFulfill.fulfill()
            return userAlerts
        }
    }
    
    private func startMonitoringContactRequestsUpdates(_ expectationToFulfill: XCTestExpectation) -> Task<[ContactRequestEntity], Never> {
        Task { [sut] in
            guard let sut else { return [] }
            var contactRequests: [ContactRequestEntity] = []
            for await updatedAlerts in sut.onContactRequestsUpdates {
                contactRequests = updatedAlerts
            }
            expectationToFulfill.fulfill()
            return contactRequests
        }
    }
}
