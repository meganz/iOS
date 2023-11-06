@testable import MEGASwift
import XCTest

final class EmptyAsyncSequenceTests: XCTestCase {
    func testEmptyAsyncSequence_neverEmitsElements() async {
        var sequenceIterator = EmptyAsyncSequence<Int>().makeAsyncIterator()
        
        let nilValue = await sequenceIterator.next()
        XCTAssertNil(nilValue)
    }
}
