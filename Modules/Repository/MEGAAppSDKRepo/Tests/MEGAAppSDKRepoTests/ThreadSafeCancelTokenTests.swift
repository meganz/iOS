import Combine
import MEGAAppSDKRepo
import MEGASdk
import XCTest

final class ThreadSafeCancelTokenTests: XCTestCase {

    func testCancel_whenCalledOnce_shouldInvokeCancelOnce() async {
        await assertCancel { sut in
            sut.cancel()
        }
    }

    func testCancel_whenCalledMultipleTimesSerially_shouldInvokeCancelOnce() async {
        await assertCancel { sut in
            (1...20).forEach { _ in sut.cancel() }
        }
    }

    func testCancel_whenCalledMultipleTimesUsingDifferentThreads_shouldInvokeCancelOnce() async {
        await assertCancel { sut in
            await withTaskGroup(of: Void.self) { group in
                group.addTasksUnlessCancelled(for: 1...20) { _ in sut.cancel() }
                await group.waitForAll()
            }
        }
    }

    // MARK: - Helpers

    private typealias SUT = ThreadSafeCancelToken

    private func makeSUT(value: MEGACancelToken) -> SUT {
        ThreadSafeCancelToken(value: value)
    }

    private func assertCancel(
        with execute: (SUT) async -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        var result: Int = 0
        let exp = expectation(description: "Wait for cancel")
        let sut = makeSUT(
            value: CancelTokenStub { i in
                result = i
                exp.fulfill()
            }
        )

        await execute(sut)

        await fulfillment(of: [exp], timeout: 1.0)

        XCTAssertEqual(result, 1, file: file, line: line)
        XCTAssertTrue(sut.value.isCancelled, file: file, line: line)
    }
}

private final class CancelTokenStub: MEGACancelToken {
    private var cancelledCalledTimes = 0
    let completion: ((Int) -> Void)

    init(completion: @escaping (Int) -> Void) {
        self.completion = completion
    }

    override func cancel() {
        super.cancel()
        cancelledCalledTimes += 1
        completion(cancelledCalledTimes)
    }
}
