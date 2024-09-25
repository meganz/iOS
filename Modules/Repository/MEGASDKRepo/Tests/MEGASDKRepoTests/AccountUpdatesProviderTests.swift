import MEGADomain
import MEGASDKRepo
import MEGASDKRepoMock
import MEGASwift
import XCTest

final class AccountUpdatesProviderTests: XCTestCase {
    private let error = MockError(errorType: .apiOk)
    private func createUserAlertList(identifiers: [UInt]) -> MockUserAlertList {
        MockUserAlertList(alerts: identifiers.map { MockUserAlert(identifier: $0) })
    }
    private func createRequest(handle: HandleEntity) -> MockRequest {
        MockRequest(handle: handle)
    }
    private let greenStorageEvent = MockEvent(
        type: .storage,
        number: EventEntity.StorageState.green.code
    )
    private let orangeStorageEvent = MockEvent(
        type: .storage,
        number: EventEntity.StorageState.orange.code
    )
    private let redStorageEvent = MockEvent(
        type: .storage,
        number: EventEntity.StorageState.red.code
    )
    
    func testAccountUpdates_onAccountRequestFinish_shouldAddRequestDelegateAndRemoveWhenTerminated() async {
        await runTest(
            startMonitoring: startMonitoringRequestFinishUpdates,
            onTaskStart: { sdk in
                XCTAssertTrue(sdk.hasRequestDelegate)
            },
            simulateEvents: { sdk in
                sdk.simulateOnRequestFinish(self.createRequest(handle: 1), error: self.error)
            },
            onTaskCancel: { sdk in
                XCTAssertFalse(sdk.hasRequestDelegate)
            },
            assertResults: { _ in }
        )
    }

    func testAccountUpdates_onAccountRequestFinish_whenNotTerminated_shouldYieldElements() async {
        await runTest(
            startMonitoring: startMonitoringRequestFinishUpdates,
            simulateEvents: { sdk in
                sdk.simulateOnRequestFinish(self.createRequest(handle: 1), error: self.error)
                sdk.simulateOnRequestFinish(self.createRequest(handle: 2), error: self.error)
            },
            assertResults: { values in
                XCTAssertEqual(values.count, 2)
            }
        )
    }

    func testAccountUpdates_onAccountRequestFinish_whenTerminated_shouldStopYieldingElements() async {
        await runTest(
            startMonitoring: startMonitoringRequestFinishUpdates,
            simulateEvents: { sdk in
                sdk.simulateOnRequestFinish(self.createRequest(handle: 1), error: self.error)
                sdk.simulateOnRequestFinish(self.createRequest(handle: 2), error: self.error)
                sdk.simulateOnRequestFinish(self.createRequest(handle: 3), error: self.error)
            },
            onTaskCancel: { sdk in
                sdk.simulateOnRequestFinish(self.createRequest(handle: 4), error: MockError(errorType: .apiOk))
            },
            assertResults: { values in
                XCTAssertEqual(values.count, 3)
            }
        )
    }

    func testAccountUpdates_onUserAlertsUpdates_shouldAddGlobalDelegateAndRemoveWhenTerminated() async {
        await runTest(
            startMonitoring: startMonitoringUserAlertsUpdates,
            onTaskStart: { sdk in
                XCTAssertTrue(sdk.hasGlobalDelegate)
            },
            simulateEvents: { sdk in
                sdk.simulateOnUserAlertsUpdate(self.createUserAlertList(identifiers: [1, 2]))
            },
            onTaskCancel: { sdk in
                XCTAssertFalse(sdk.hasGlobalDelegate)
            },
            assertResults: { _ in }
        )
    }
    
    func testAccountUpdates_onUserAlertsUpdates_whenNotTerminated_shouldYieldElements() async {
        await runTest(
            startMonitoring: startMonitoringUserAlertsUpdates,
            simulateEvents: { sdk in
                // Trigger new alerts before terminating stream. Expected values from the last trigger.
                sdk.simulateOnUserAlertsUpdate(MockUserAlertList(alerts: [MockUserAlert(identifier: 1), MockUserAlert(identifier: 2)]))
                sdk.simulateOnUserAlertsUpdate(MockUserAlertList(alerts: [MockUserAlert(identifier: 3), MockUserAlert(identifier: 4)]))
                sdk.simulateOnUserAlertsUpdate(MockUserAlertList(alerts: [MockUserAlert(identifier: 5), MockUserAlert(identifier: 6)]))
            },
            assertResults: { values in
                XCTAssertEqual(values.map(\.identifier), [5, 6])
            }
        )
    }

    func testAccountUpdates_onUserAlertsUpdates_whenTerminated_shouldStopYieldingElements() async {
        await runTest(
            startMonitoring: startMonitoringUserAlertsUpdates,
            simulateEvents: { sdk in
                sdk.simulateOnUserAlertsUpdate(self.createUserAlertList(identifiers: [1, 2]))
            },
            onTaskCancel: { sdk in
                sdk.simulateOnUserAlertsUpdate(self.createUserAlertList(identifiers: [3, 4]))
            },
            assertResults: { values in
                XCTAssertEqual(values.map(\.identifier), [1, 2])
            }
        )
    }

    func testAccountUpdates_onStorageStatusUpdates_shouldAddGlobalDelegateAndRemoveWhenTerminated() async {
        await runTest(
            startMonitoring: startMonitoringStorageStatusUpdates,
            onTaskStart: { sdk in
                XCTAssertTrue(sdk.hasGlobalDelegate)
            },
            simulateEvents: { sdk in
                sdk.simulateOnEvent(self.greenStorageEvent)
            },
            onTaskCancel: { sdk in
                XCTAssertFalse(sdk.hasGlobalDelegate)
            },
            assertResults: { _ in }
        )
    }

    func testAccountUpdates_onStorageStatusUpdates_whenNotTerminated_shouldYieldElements() async {
        await runTest(
            areSOQBannersEnabled: true,
            startMonitoring: startMonitoringStorageStatusUpdates,
            simulateEvents: { sdk in
                sdk.simulateOnEvent(self.greenStorageEvent)
                sdk.simulateOnEvent(self.orangeStorageEvent)
                sdk.simulateOnEvent(self.redStorageEvent)
            },
            assertResults: { values in
                XCTAssertEqual(values, [.noStorageProblems, .almostFull, .full])
            }
        )
    }

    func testAccountUpdates_onStorageStatusUpdates_whenTerminated_shouldStopYieldingElements() async {
        await runTest(
            areSOQBannersEnabled: true,
            startMonitoring: startMonitoringStorageStatusUpdates,
            simulateEvents: { sdk in
                sdk.simulateOnEvent(self.greenStorageEvent)
            },
            onTaskCancel: { sdk in
                sdk.simulateOnEvent(self.redStorageEvent)
            },
            assertResults: { values in
                XCTAssertEqual(values, [.noStorageProblems])
            }
        )
    }
    
    // MARK: - Helpers
    private func makeSUT(areSOQBannersEnabled: Bool = false) -> (AccountUpdatesProvider, MockSdk) {
        let sdk = MockSdk(shouldListGlobalDelegates: true)
        let sut = AccountUpdatesProvider(
            sdk: sdk,
            areSOQBannersEnabled: { areSOQBannersEnabled }
        )
        return (sut, sdk)
    }

    private func startMonitoringRequestFinishUpdates(
        sut: AccountUpdatesProvider,
        expectationToFulfill: XCTestExpectation
    ) -> Task<[Result<AccountRequestEntity, any Error>], Never> {
        startMonitoringUpdates(asyncSequence: sut.onAccountRequestFinish, expectationToFulfill: expectationToFulfill)
    }

    private func startMonitoringUserAlertsUpdates(
        sut: AccountUpdatesProvider,
        expectationToFulfill: XCTestExpectation
    ) -> Task<[UserAlertEntity], Never> {
        Task {
            var userAlerts: [UserAlertEntity] = []
            for await updatedAlerts in sut.onUserAlertsUpdates {
                userAlerts = updatedAlerts
            }
            expectationToFulfill.fulfill()
            return userAlerts
        }
    }

    private func startMonitoringContactRequestsUpdates(
        sut: AccountUpdatesProvider,
        expectationToFulfill: XCTestExpectation
    ) -> Task<[ContactRequestEntity], Never> {
        startMonitoringUpdatesFromArray(asyncSequence: sut.onContactRequestsUpdates, expectationToFulfill: expectationToFulfill)
    }

    private func startMonitoringStorageStatusUpdates(
        sut: AccountUpdatesProvider,
        expectationToFulfill: XCTestExpectation
    ) -> Task<[StorageStatusEntity], Never> {
        startMonitoringUpdates(
            asyncSequence: sut.onStorageStatusUpdates,
            expectationToFulfill: expectationToFulfill
        )
    }

    private func runTest<T>(
        areSOQBannersEnabled: Bool = false,
        startMonitoring: @escaping (AccountUpdatesProvider, XCTestExpectation) -> Task<[T], Never>,
        onTaskStart: @escaping (MockSdk) -> Void = { _ in },
        simulateEvents: @escaping (MockSdk) -> Void,
        onTaskCancel: @escaping (MockSdk) -> Void = { _ in },
        assertResults: @escaping ([T]) -> Void
    ) async {
        let (sut, sdk) = makeSUT(areSOQBannersEnabled: areSOQBannersEnabled)
        let expectation = expectation(description: "Updates")
        let task = startMonitoring(sut, expectation)

        try? await Task.sleep(nanoseconds: 100_000_000)

        onTaskStart(sdk)

        simulateEvents(sdk)
        task.cancel()

        try? await Task.sleep(nanoseconds: 100_000_000)

        onTaskCancel(sdk)

        await fulfillment(of: [expectation], timeout: 1)

        let values = await task.value

        assertResults(values)
    }
    
    private func startMonitoringUpdates<T>(
        asyncSequence: AnyAsyncSequence<T>,
        expectationToFulfill: XCTestExpectation
    ) -> Task<[T], Never> {
        Task {
            var results: [T] = []
            for await result in asyncSequence {
                results.append(result)
            }
            expectationToFulfill.fulfill()
            return results
        }
    }

    private func startMonitoringUpdatesFromArray<T>(
        asyncSequence: AnyAsyncSequence<[T]>,
        expectationToFulfill: XCTestExpectation
    ) -> Task<[T], Never> {
        Task {
            var results: [T] = []
            for await resultArray in asyncSequence {
                results.append(contentsOf: resultArray)
            }
            expectationToFulfill.fulfill()
            return results
        }
    }
}
