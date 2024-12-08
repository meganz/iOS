import MEGADomain
import MEGASdk
import MEGASDKRepo
import MEGASDKRepoMock
import MEGASwift
import Testing
import XCTest

final class RubbishBinSettingsUpdateProviderTests: XCTestCase {
    
    func testSettingsUpdates_onRequestFinish_shouldAddRequestDelegateAndRemoveWhenTerminated() async {
        let error = MockError(errorType: .apiOk)
        
        await runTest(
            startMonitoring: startMonitoringRequestFinishUpdates,
            onTaskStart: { sdk in
                #expect(sdk.hasRequestDelegate)
            },
            simulateEvents: { sdk in
                sdk.simulateOnRequestFinish(self.createRequest(handle: 1,
                                                               requestType: .MEGARequestTypeGetAttrUser,
                                                               parameterType: .rubbishTime), error: error)
            },
            onTaskCancel: { sdk in
                #expect(!sdk.hasRequestDelegate)
            },
            assertResults: { _ in }
        )
    }
    
    func testSettingsUpdates_onRequestFinishAndNotTerminated_shouldYieldElements() async {
        let error = MockError(errorType: .apiOk)
        
        await runTest(
            startMonitoring: startMonitoringRequestFinishUpdates,
            simulateEvents: { sdk in
                sdk.simulateOnRequestFinish(self.createRequest(handle: 1,
                                                               requestType: .MEGARequestTypeGetAttrUser,
                                                               parameterType: .rubbishTime), error: error)
                sdk.simulateOnRequestFinish(self.createRequest(handle: 2,
                                                               requestType: .MEGARequestTypeGetAttrUser,
                                                               parameterType: .rubbishTime), error: error)
            },
            assertResults: { results in
                #expect(results.count == 2)
            }
        )
    }
    
    func testSettingsUpdates_onRequestFinishAndTerminated_shouldStopYieldingElements() async {
        let error = MockError(errorType: .apiOk)
        
        await runTest(
            startMonitoring: startMonitoringRequestFinishUpdates,
            simulateEvents: { sdk in
                sdk.simulateOnRequestFinish(self.createRequest(handle: 1,
                                                               requestType: .MEGARequestTypeGetAttrUser,
                                                               parameterType: .rubbishTime), error: error)
                sdk.simulateOnRequestFinish(self.createRequest(handle: 2,
                                                               requestType: .MEGARequestTypeGetAttrUser,
                                                               parameterType: .rubbishTime), error: error)
                sdk.simulateOnRequestFinish(self.createRequest(handle: 3,
                                                               requestType: .MEGARequestTypeGetAttrUser,
                                                               parameterType: .rubbishTime), error: error)
            },
            onTaskCancel: { sdk in
                sdk.simulateOnRequestFinish(self.createRequest(handle: 4,
                                                               requestType: .MEGARequestTypeGetAttrUser,
                                                               parameterType: .rubbishTime), error: error)
            },
            assertResults: { results in
                #expect(results.count == 3)
            })
    }
    
    func testSettingsUpdates_paidAccountOnRequestFinishWithErrorApiENoent_rubbishBinAutoPurgePeriodShouldBe90() async {
        let error = MockError(errorType: .apiENoent)
        
        await runTest(
            startMonitoring: startMonitoringRequestFinishUpdates,
            simulateEvents: { sdk in
                sdk.simulateOnRequestFinish(self.createRequest(handle: 1,
                                                               requestType: .MEGARequestTypeGetAttrUser,
                                                               parameterType: .rubbishTime), error: error)
            },
            assertResults: { results in
                #expect(results.count == 1)
                
                guard case .success(let entity) = results.first else {
                    Issue.record("Errors happen.")
                    return
                }
                
                #expect(entity.rubbishBinAutopurgePeriod == RubbishBinSettingsUpdateProvider.autopurgePeriodForPaidAccount)
            }
        )
    }
    
    // MARK: - Helpers
    
    private func createRequest(handle: HandleEntity, requestType: MEGARequestType, parameterType: MEGAUserAttribute) -> MockRequest {
        MockRequest(handle: handle, requestType: requestType, parameterType: parameterType)
    }
    
    private func startMonitoringRequestFinishUpdates(
        sut: RubbishBinSettingsUpdateProvider,
        expectationToFulfill: XCTestExpectation
    ) -> Task<[Result<RubbishBinSettingsEntity, any Error>], Never> {
        startMonitoringUpdates(asyncSequence: sut.onRubbishBinSettingsRequestFinish, expectationToFulfill: expectationToFulfill)
    }
    
    private func makeSUT(isProAccount: Bool = false,
                         serverSideRubbishBinAutopurgeEnabled: Bool = true) -> (RubbishBinSettingsUpdateProvider, MockSdk) {
        let sdk = MockSdk()
        let sut = RubbishBinSettingsUpdateProvider(sdk: sdk,
                                                   isPaidAccount: isProAccount,
                                                   serverSideRubbishBinAutopurgeEnabled: serverSideRubbishBinAutopurgeEnabled)
        return (sut, sdk)
    }
    
    private func runTest<T>(
        startMonitoring: @escaping (RubbishBinSettingsUpdateProvider, XCTestExpectation) -> Task<[T], Never>,
        onTaskStart: @escaping (MockSdk) -> Void = { _ in },
        simulateEvents: @escaping (MockSdk) -> Void,
        onTaskCancel: @escaping (MockSdk) -> Void = { _ in },
        assertResults: @escaping ([T]) -> Void
    ) async {
        let (sut, sdk) = makeSUT()
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
}
