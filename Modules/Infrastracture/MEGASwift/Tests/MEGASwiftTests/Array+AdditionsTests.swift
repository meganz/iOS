@testable import MEGASwift
import XCTest

final class ArrayAdditionsTests: XCTestCase {
    private let testArray = [1, 2, 3, 4, 5]
    
    func testSafeSubscript() {
        XCTAssertEqual(testArray[safe: 0], 1)
        XCTAssertEqual(testArray[safe: 2], 3)
        XCTAssertEqual(testArray[safe: 4], 5)
        XCTAssertNil(testArray[safe: 5])
        XCTAssertNil(testArray[safe: -1])
    }
    
    func testMoveItemToNewIndex() {
        var array = [1, 2, 3, 4, 5]
        
        array.move(3, to: 0)
        XCTAssertEqual(array, [3, 1, 2, 4, 5])
        
        array.move(5, to: 2)
        XCTAssertEqual(array, [3, 1, 5, 2, 4])
        
        array.move(2, to: 4)
        XCTAssertEqual(array, [3, 1, 5, 4, 2])
    }
    
    func testBringItemToFront() {
        var array = [1, 2, 3, 4, 5]
        
        array.bringToFront(item: 3)
        XCTAssertEqual(array, [3, 1, 2, 4, 5])
        
        array.bringToFront(item: 5)
        XCTAssertEqual(array, [5, 3, 1, 2, 4])
    }
    
    func testSendItemToBack() {
        var array = [1, 2, 3, 4, 5]
        
        array.sendToBack(item: 3)
        XCTAssertEqual(array, [1, 2, 4, 5, 3])
        
        array.sendToBack(item: 1)
        XCTAssertEqual(array, [2, 4, 5, 3, 1])
    }
    
    func testShiftedArray() {
        XCTAssertEqual(testArray.shifted(), [2, 3, 4, 5, 1])
        XCTAssertEqual(testArray.shifted(2), [3, 4, 5, 1, 2])
        XCTAssertEqual(testArray.shifted(-1), [5, 1, 2, 3, 4])
    }
    
    func testMoveAtIndexToNewIndex() {
        var array = [1, 2, 3, 4, 5]
        
        array.move(at: 2, to: 0)
        XCTAssertEqual(array, [3, 1, 2, 4, 5])
        
        array.move(at: 4, to: 2)
        XCTAssertEqual(array, [3, 1, 5, 2, 4])
        
        array.move(at: 2, to: 4)
        XCTAssertEqual(array, [3, 1, 2, 4, 5])
    }
    
    func testRemoveDuplicatesWhileKeepingOriginalOrder() {
        let array = [1, 2, 3, 2, 4, 1, 5, 3]
        
        XCTAssertEqual(array.removeDuplicatesWhileKeepingTheOriginalOrder(), [1, 2, 3, 4, 5])
    }
    
    func testRemoveObjectFromArray() {
        var array = [1, 2, 3, 4, 5]
        
        array.remove(object: 3)
        XCTAssertEqual(array, [1, 2, 4, 5])
        
        array.remove(object: 5)
        XCTAssertEqual(array, [1, 2, 4])
        
        array.remove(object: 1)
        XCTAssertEqual(array, [2, 4])
    }

    func testElementsPrepended() {
        XCTAssertEqual(
            ["test1", "test2", "test3", "test4"].elementsPrepended(with: "#"),
            ["#test1", "#test2", "#test3", "#test4"]
        )
    }
}
