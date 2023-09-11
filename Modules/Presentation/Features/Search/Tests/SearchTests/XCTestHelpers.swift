import XCTest

extension XCTestCase {
    func wait(
        file: StaticString = #filePath,
        line: UInt = #line,
        until: @escaping () -> Bool
    ) async {
        let predicate = NSPredicate { _, _ in
            until()
        }
        let expectation = expectation(for: predicate, evaluatedWith: nil)
        await fulfillment(of: [expectation], timeout: 10)
    }
}
