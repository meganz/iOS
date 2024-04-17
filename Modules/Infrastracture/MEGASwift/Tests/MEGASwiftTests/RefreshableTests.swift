import XCTest
@testable import MEGASwift

final class RefreshableTests: XCTestCase {
    private struct TestStruct: Refreshable {
        let value: Int
        
        static func ↻↻(lhs: TestStruct, rhs: TestStruct) -> Bool {
            return lhs.value == rhs.value
        }
    }
    
    private let struct1 = TestStruct(value: 10)
    private let struct2 = TestStruct(value: 10)
    private let struct3 = TestStruct(value: 20)
    
    func testRefreshableOperator() {
        XCTAssertTrue(struct1 ↻↻ struct2)
        XCTAssertFalse(struct1 ↻↻ struct3)
    }
    
    func testNotRefreshableOperator() {
        XCTAssertFalse(struct1 !↻ struct2)
        XCTAssertTrue(struct1 !↻ struct3)
    }
}

final class RefreshableWhenVisibleTests: XCTestCase {
    private struct TestStruct: RefreshableWhenVisible {
        let value: Int
        
        static func ↻↻⏿(lhs: TestStruct, rhs: TestStruct) -> Bool {
            return lhs.value == rhs.value
        }
    }
    private let struct1 = TestStruct(value: 10)
    private let struct2 = TestStruct(value: 10)
    private let struct3 = TestStruct(value: 20)
    
    func testRefreshableWhenVisibleOperator() {
        XCTAssertTrue(struct1 ↻↻⏿ struct2)
        XCTAssertFalse(struct1 ↻↻⏿ struct3)
    }
    
    func testNotRefreshableWhenVisibleOperator() {
        XCTAssertFalse(struct1 !↻⏿ struct2)
        XCTAssertTrue(struct1 !↻⏿ struct3)
    }
}
