import XCTest

final class EquatableExtensionTests: XCTestCase {
    func testIsEqual_withSameValues_shouldReturnTrue() {
        let lhs = 5
        let rhs = 5
        
        let result = lhs.isEqual(rhs)
        
        XCTAssertTrue(result)
    }
    
    func testIsEqual_withDifferentValues_shouldReturnFalse() {
        let lhs = "Hello"
        let rhs = "World"
        
        let result = lhs.isEqual(rhs)
        
        XCTAssertFalse(result)
    }
    
    func testIsEqual_withNil_shouldReturnFalse() {
        let lhs = 10
        let rhs: Int? = nil
        
        let result = lhs.isEqual(rhs)
        
        XCTAssertFalse(result)
    }
    
    func testIsEqual_withDifferentTypes_shouldReturnFalse() {
        let lhs = 3.14
        let rhs = "3.14"
        
        let result = lhs.isEqual(rhs)
        
        XCTAssertFalse(result)
    }
}
