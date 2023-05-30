import XCTest

extension XCTestCase {
    
    func trackForMemoryLeaks(on instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been deallocated, potential memory leak.", file: file, line: line)
        }
    }
}
