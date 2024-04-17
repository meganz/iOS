@testable import MEGASwift
import XCTest

final class OptionSetAdditionsTests: XCTestCase {
    private struct TestOptions: OptionSet {
        let rawValue: Int
        
        static let option1 = TestOptions(rawValue: 1)
        static let option2 = TestOptions(rawValue: 2)
    }
    
    func testIsNotEmpty_withEmptyArray_shouldReturnFalse() {
        let emptyOptions: TestOptions = []
        XCTAssertFalse(emptyOptions.isNotEmpty)
    }
    
    func testIsNotEmpty_withNotEmptyArray_shouldReturnTrue() {
        let nonEmptyOptions: TestOptions = [.option1, .option2]
        XCTAssertTrue(nonEmptyOptions.isNotEmpty)
    }
}
