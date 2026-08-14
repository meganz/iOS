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
        let delay = defaultDelay
        let debouncer = Debouncer(delay: delay)
        let startTime = Date()

        debouncer.start {
            let elapsedTime = Date().timeIntervalSince(startTime)
            XCTAssertGreaterThanOrEqual(elapsedTime, delay, "Action should be executed after the delay")
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

    func testMultipleStarts_whenCalledMultipleTimes_shouldOnlyExecuteLastAction() {
        let expectation = XCTestExpectation(description: "Only the last action should be called")
        let debouncer = Debouncer(delay: defaultDelay)
        let callCount = CallCounter()

        func performStartAction() {
            debouncer.start {
                callCount.increment()
                expectation.fulfill()
            }
        }

        performStartAction()
        performStartAction()
        performStartAction()

        wait(for: [expectation], timeout: defaultTimeOut)

        XCTAssertEqual(callCount.value, 1)
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

/// `Debouncer.Action` is `@Sendable`, so a captured `var` cannot be mutated from
/// inside it. This keeps the counter usable across isolation domains.
private final class CallCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    func increment() {
        lock.lock()
        defer { lock.unlock() }
        count += 1
    }

    var value: Int {
        lock.lock()
        defer { lock.unlock() }
        return count
    }
}
