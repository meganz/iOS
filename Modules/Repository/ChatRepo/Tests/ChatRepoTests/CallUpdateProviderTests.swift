import ChatRepo
import ChatRepoMock
import XCTest

final class CallUpdateProviderTests: XCTestCase {
    func testCallUpdate_onSequenceCreation_shouldAddCallDelegateAndRemoveWhenTerminated() async {
        let sdk = MockChatSDK()
        let sut = CallUpdateProvider(sdk: sdk)
        
        let finished = expectation(description: "finished")
        let task = Task {
            for await _ in sut.callUpdate {}
            finished.fulfill()
        }
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertTrue(sdk.hasChatCallDelegate)
        XCTAssertEqual(sdk.delegateQueueType, .globalBackground)
        task.cancel()
        await fulfillment(of: [finished], timeout: 0.5)
        
        XCTAssertFalse(sdk.hasChatCallDelegate)
    }
}
