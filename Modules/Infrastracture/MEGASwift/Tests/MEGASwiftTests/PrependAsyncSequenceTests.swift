import MEGASwift
import XCTest

final class PrependAsyncSequenceTests: XCTestCase {
    func testPrepend_onAsyncStream_addItemAsFirstItemOnIteration() async {
        let stream = AsyncStream<Int> { continuation in
            for i in 0..<5 {
                continuation.yield(i)
            }
            continuation.finish()
        }
        
        var iterator = stream.prepend(10).makeAsyncIterator()
        
        var result = [Int]()
        while let item = await iterator.next() {
            result.append(item)
        }
        
        XCTAssertEqual(result, [10, 0, 1, 2, 3, 4])
    }
    
    func testPrepend_onThrowingAsyncStream_addItemAsFirstItemOnIteration() async throws {
        let stream = AsyncThrowingStream<Int, Error> { continuation in
            for i in 0..<5 {
                continuation.yield(i)
            }
            continuation.finish()
        }
        
        var iterator = stream.prepend(10).makeAsyncIterator()
        
        var result = [Int]()
        while let item = try await iterator.next() {
            result.append(item)
        }
        
        XCTAssertEqual(result, [10, 0, 1, 2, 3, 4])
    }
    
    func testPrepend_onTransformations_addItemAsFirstItemOnIterationBeforeTransformations() async {
        let stream = AsyncStream<Int> { continuation in
            for i in 0..<5 {
                continuation.yield(i)
            }
            continuation.finish()
        }
        
        var iterator = stream
            .map { $0 * 2}
            .filter { $0 < 4}
            .prepend(10)
            .makeAsyncIterator()
        
        var result = [Int]()
        while let item = await iterator.next() {
            result.append(item)
        }
        
        XCTAssertEqual(result, [10, 0, 2])
    }
    
    func testPrepend_onEmptySequence_shouldOnlyEmitPrependedItem() async {
        let item = "Hello"
        
        var iterator = AsyncStream<String> { $0.finish() }
            .prepend(item)
            .makeAsyncIterator()
        
        let result = await iterator.next()
        XCTAssertEqual(result, item)
        
        let emptyResult = await iterator.next()
        XCTAssertNil(emptyResult)
    }
}
