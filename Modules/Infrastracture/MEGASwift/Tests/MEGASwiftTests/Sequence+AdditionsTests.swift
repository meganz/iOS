import XCTest
@testable import MEGASwift

final class SequenceAdditionsTests: XCTestCase {
    private let numbers = [1, 2, 3, 4, 5]
    
    func testNotContains_withPredicateInTheSequence_shouldReturnFalse() {
        XCTAssertFalse(numbers.notContains { $0 > 3 })
    }
    
    func testNotContains_withouthPredicateInTheSequence_shouldReturnTrue() {
        XCTAssertTrue(numbers.notContains { $0 > 5 })
    }
    
    func testNotContains_withElementInTheSequence_shouldReturnFalse() {
        XCTAssertFalse(numbers.notContains(3))
    }
    
    func testNotContains_withoutElementInTheSequence_shouldReturnTrue() {
        XCTAssertTrue(numbers.notContains(6))
    }
}
