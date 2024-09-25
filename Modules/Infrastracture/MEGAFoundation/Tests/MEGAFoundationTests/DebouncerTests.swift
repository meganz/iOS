@testable import MEGAFoundation
import XCTest

final class DebouncerTests: XCTestCase {
    let defaultDelay: TimeInterval = 0.1
    let defaultTimeOut: TimeInterval = 2.0

    func testInitialization_whenCalled_shouldCreateDebouncer() {
        let debouncer = Debouncer(delay: 1.0)
        XCTAssertNotNil(debouncer, "Debouncer should be created successfully.")
    }

    func testStartAction_whenCalled_shouldExecuteActionAfterDelay() {
        let expectation = XCTestExpectation(description: "Action should be called after delay")
        let debouncer = Debouncer(delay: defaultDelay)
        let startTime = Date()

        debouncer.start {
            let elapsedTime = Date().timeIntervalSince(startTime)
            XCTAssertGreaterThanOrEqual(elapsedTime, self.defaultDelay, "Action should be executed after the delay")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: defaultTimeOut + defaultDelay)
    }

    func testCancel_whenCalled_shouldPreventActionExecution() async throws {
        let expectation = XCTestExpectation(description: "Action should not be called")
        expectation.isInverted = true
        
        let debouncer = Debouncer(delay: defaultDelay)
        debouncer.start {
            expectation.fulfill()
        }
        
        try await Task.sleep(nanoseconds: 50_000_000)
        debouncer.cancel()
        
        await fulfillment(of: [expectation], timeout: defaultTimeOut)
    }

    func testDebounceAsync_whenCalled_shouldWaitForSpecifiedDelay() async throws {
        let debouncer = Debouncer(delay: defaultDelay)

        let startTime = Date()
        try await debouncer.debounce()
        let endTime = Date()

        let elapsed = endTime.timeIntervalSince(startTime)
        XCTAssertGreaterThanOrEqual(elapsed, defaultDelay)
    }

    func testMultipleStarts_whenCalledMultipleTimes_shouldOnlyExecuteLastAction() {
        let expectation = XCTestExpectation(description: "Only the last action should be called")
        let debouncer = Debouncer(delay: defaultDelay)
        var callCount = 0
        let queue = DispatchQueue(label: "testQueue", attributes: .concurrent)
        
        func performStartAction(with delay: TimeInterval) {
            queue.asyncAfter(deadline: .now() + delay) {
                debouncer.start {
                    callCount += 1
                    expectation.fulfill()
                }
            }
        }

        performStartAction(with: 0.0)
        performStartAction(with: 0.02)
        performStartAction(with: 0.04)

        wait(for: [expectation], timeout: defaultTimeOut)

        XCTAssertEqual(callCount, 1)
    }

    func testConcurrentAccess_whenCalledConcurrently_shouldDebounceCorrectly() {
        let expectation = XCTestExpectation(description: "Actions should be debounced correctly under concurrent access")
        expectation.expectedFulfillmentCount = 1

        let debouncer = Debouncer(delay: defaultDelay)
        let queue = DispatchQueue(label: "testQueue", attributes: .concurrent)
        let group = DispatchGroup()

        for _ in 0..<100 {
            group.enter()
            queue.async {
                debouncer.start {
                    expectation.fulfill()
                }
                group.leave()
            }
        }

        group.notify(queue: DispatchQueue.main) {
            self.wait(for: [expectation], timeout: self.defaultTimeOut)
        }
    }
}
