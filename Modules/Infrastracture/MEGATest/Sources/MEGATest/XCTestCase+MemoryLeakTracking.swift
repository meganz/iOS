import XCTest

public extension XCTestCase {
    func trackForMemoryLeaks(on instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been deallocated, potential memory leak.", file: file, line: line)
        }
    }
    
    func trackForMemoryLeaks(on instance: (AnyObject & Sendable), timeoutNanoseconds: UInt64, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak instance] in

            // Add sleep to give time to deinit. Could not see any retain cycles in instruments or when debugging deinit
            try await Task.sleep(nanoseconds: timeoutNanoseconds)

            XCTAssertNil(instance, "Instance should have been deallocated, potential memory leak.", file: file, line: line)
        }
    }
}
