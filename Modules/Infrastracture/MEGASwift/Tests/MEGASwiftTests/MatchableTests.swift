@testable import MEGASwift
import XCTest

final class MatchableTests: XCTestCase {
    func testArrayMatchable() {
        let array1 = [1, 2, 3]
        let array2 = [1, 2, 3]
        let array3 = [1, 2, 4]
        let array4 = [1, 2, 3, 4]
        
        XCTAssertTrue(array1 ~~ array2)
        XCTAssertFalse(array1 ~~ array3)
        XCTAssertFalse(array1 ~~ array4)
    }
    
    func testOptionalMatchable() {
        let optional1: Int? = 5
        let optional2: Int? = 5
        let optional3: Int? = 10
        let optional4: Int? = nil
        
        XCTAssertTrue(optional1 ~~ optional2)
        XCTAssertFalse(optional1 ~~ optional3)
        XCTAssertFalse(optional1 ~~ optional4)
        XCTAssertTrue(optional4 ~~ nil)
    }
    
    func testNegatedMatchable() {
        let int1 = 5
        let int2 = 10
        
        XCTAssertTrue(int1 !~ int2)
        XCTAssertFalse(int1 !~ int1)
    }
}

extension Int: Matchable {
    public static func ~~ (lhs: Int, rhs: Int) -> Bool {
        lhs == rhs
    }
}
