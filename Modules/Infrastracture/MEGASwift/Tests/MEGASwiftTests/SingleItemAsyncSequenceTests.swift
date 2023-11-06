@testable import MEGASwift
import XCTest

final class SingleItemAsyncSequenceTests: XCTestCase {
    func testSingleItemAsyncSequence_onlyEmitsOneItem() async {
        let value = 65
        var sequenceIterator = SingleItemAsyncSequence(item: value).makeAsyncIterator()
        
        let firstValue = await sequenceIterator.next()
        XCTAssertEqual(firstValue, value)
        
        let nilValue = await sequenceIterator.next()
        XCTAssertNil(nilValue)
    }
}
