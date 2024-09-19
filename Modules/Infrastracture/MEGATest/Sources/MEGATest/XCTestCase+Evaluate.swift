import XCTest

extension XCTestCase {
    public func evaluate(isInverted: Bool = false, expression: @escaping () -> Bool) {
        let predicate = NSPredicate { _, _ in expression() }
        let expectation = expectation(for: predicate, evaluatedWith: nil)
        expectation.isInverted = isInverted
        wait(for: [expectation], timeout: 5)
    }
    
    @MainActor
    public func evaluateAsync(isInverted: Bool = false, expression: @escaping () -> Bool) async {
        let predicate = NSPredicate { _, _ in expression() }
        let expectation = expectation(for: predicate, evaluatedWith: nil)
        expectation.isInverted = isInverted
        await fulfillment(of: [expectation], timeout: 5)
    }
}
