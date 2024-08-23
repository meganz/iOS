import MEGADomain
import MEGASDKRepo
import MEGASDKRepoMock
import XCTest

final class NodeTransferCompletionUpdatesProviderTests: XCTestCase {
    private var sdk: MockSdk!
    private var sharedFolderSdk: MockFolderSdk!
    private var sut: NodeTransferCompletionUpdatesProvider!
    
    override func setUp() {
        super.setUp()
        sdk = MockSdk()
        sharedFolderSdk = MockFolderSdk()
        sut = NodeTransferCompletionUpdatesProvider(sdk: sdk, sharedFolderSdk: sharedFolderSdk)
    }
    
    override func tearDown() {
        sdk = nil
        sharedFolderSdk = nil
        sut = nil
        super.tearDown()
    }
    
    func testNodeTransferUpdates_whenNodeTransferComplete_shouldYieldElements() async throws {
        // given
        let expectation = expectation(description: #function)
        
        let task = startMonitoringNodeTransferCompletionUpdates(expectation)
        
        // this is necessary for the delegate to be added before the below simulateOnTransferFinish get called.
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // when
        sdk.simulateOnTransferFinish(MockTransfer(nodeHandle: 1), error: MockError(errorType: .apiOk))
        sharedFolderSdk.simulateOnTransferFinish(MockTransfer(nodeHandle: 2), error: MockError(errorType: .apiOk))
        
        task.cancel()
        
        await fulfillment(of: [expectation], timeout: 1)
        
        // then
        let values = await task.value
        XCTAssertEqual(values.map(\.nodeHandle), [1, 2])
    }
    
    func testNodeTransferUpdates_whenTerminate_shouldStopYieldingElements() async throws {
        // given
        let expectation = expectation(description: #function)
        
        let task = startMonitoringNodeTransferCompletionUpdates(expectation)
        
        // this is necessary for the delegate to be added before the below simulateOnTransferFinish get called.
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // then
        XCTAssertTrue(sdk.hasTransferDelegate)
        
        // when
        sdk.simulateOnTransferFinish(MockTransfer(nodeHandle: 1), error: MockError(errorType: .apiOk))
        
        task.cancel()
        
        // this is necessary for the delegate to be removed before the below simulateOnTransferFinish get called.
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        sdk.simulateOnTransferFinish(MockTransfer(nodeHandle: 2), error: MockError(errorType: .apiOk))
        
        await fulfillment(of: [expectation], timeout: 1)
        
        // then
        XCTAssertFalse(sdk.hasTransferDelegate)
        
        let values = await task.value
        XCTAssertEqual(values.map(\.nodeHandle), [1])
    }
    
    func testNodeTransferUpdates_whenNodeTransferFailsWithError_shouldSkipYieldingElement() async throws {
        // given
        let expectation = expectation(description: #function)
        
        let task = startMonitoringNodeTransferCompletionUpdates(expectation)
        
        // this is necessary for the delegate to be added before the below simulateOnTransferFinish get called.
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // when
        sdk.simulateOnTransferFinish(MockTransfer(nodeHandle: 1), error: MockError(errorType: .apiOk))
        sdk.simulateOnTransferFinish(MockTransfer(nodeHandle: 2), error: MockError(errorType: .apiEExist))
        
        task.cancel()
        
        await fulfillment(of: [expectation], timeout: 1)
        
        // then
        let values = await task.value
        XCTAssertEqual(values.map(\.nodeHandle), [1])
    }
    
    private func startMonitoringNodeTransferCompletionUpdates(_ expectationToFulfill: XCTestExpectation) -> Task<[TransferEntity], Never> {
        Task { [sut] in
            guard let sut else { return [] }
            var transfers: [TransferEntity] = []
            
            for await transfer in sut.nodeTransferUpdates {
                transfers.append(transfer)
            }
            
            expectationToFulfill.fulfill()
            
            return transfers
        }
    }
}
