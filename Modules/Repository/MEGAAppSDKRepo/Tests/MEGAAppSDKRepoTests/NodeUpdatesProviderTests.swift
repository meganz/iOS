import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import XCTest

final class NodeUpdatesProviderTests: XCTestCase {
    func testNodeUpdates_onSequenceCreation_shouldAddGlobalDelegateAndRemoveWhenTerminated() async {
        let sdk = MockSdk()
        let sut = NodeUpdatesProvider(sdk: sdk)
        
        let finished = expectation(description: "finished")
        let task = Task {
            for await _ in sut.nodeUpdates {}
            finished.fulfill()
        }
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertTrue(sdk.hasGlobalDelegate)
        XCTAssertEqual(sdk.delegateQueueType, .globalBackground)
        task.cancel()
        await fulfillment(of: [finished], timeout: 0.5)
        
        XCTAssertFalse(sdk.hasGlobalDelegate)
    }
}
