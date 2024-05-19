import MEGASwift
import XCTest

final class PrependThrowingAsyncSequenceTests: XCTestCase {
    func testPrepend_onAsyncStream_addItemAsFirstItemOnIteration() async throws {
        let stream = AsyncStream<String> { continuation in
            for i in 0..<5 {
                continuation.yield("\(i)")
            }
            continuation.finish()
        }
        
        var iterator = stream.prepend {
            try await Task.sleep(nanoseconds: 1_000_000)
            return "22"
        }.makeAsyncIterator()
        
        var result = [String]()
        while let item = try await iterator.next() {
            result.append(item)
        }
        
        XCTAssertEqual(result, ["22", "0", "1", "2", "3", "4"])
    }
    
    func testPrepend_onThrowingAsyncStream_addItemAsFirstItemOnIteration() async throws {
        let stream = AsyncThrowingStream<String, Error> { continuation in
            for i in 0..<5 {
                continuation.yield("\(i)")
            }
            continuation.finish()
        }
        
        var iterator = stream.prepend {
            try await Task.sleep(nanoseconds: 1_000_000)
            return "55"
        }.makeAsyncIterator()
        
        var result = [String]()
        while let item = try await iterator.next() {
            result.append(item)
        }
        
        XCTAssertEqual(result, ["55", "0", "1", "2", "3", "4"])
    }
    
    func testPrepend_onTransformations_addItemAsFirstItemOnIterationBeforeTransformations() async throws {
        let stream = AsyncStream<Int> { continuation in
            for i in 0..<5 {
                continuation.yield(i)
            }
            continuation.finish()
        }
        
        var iterator = stream
            .map { $0 * 2}
            .filter { $0 < 4}
            .prepend {
                try await Task.sleep(nanoseconds: 1_000_000)
                return 10
            }
            .makeAsyncIterator()
        
        var result = [Int]()
        while let item = try await iterator.next() {
            result.append(item)
        }
        
        XCTAssertEqual(result, [10, 0, 2])
    }
    
    func testPrepend_onEmptySequence_shouldOnlyEmitPrependedItem() async throws {
        let item = "Hello"
        
        var iterator = AsyncStream<String> { $0.finish() }
            .prepend {
                try await Task.sleep(nanoseconds: 1_000_000)
                return item
            }
            .makeAsyncIterator()
        
        let result = try await iterator.next()
        XCTAssertEqual(result, item)
        
        let emptyResult = try await iterator.next()
        XCTAssertNil(emptyResult)
    }
    
    func testPrepend_onPrependThrows_shouldCancelSequenceAndNotEmitMoreItems() async throws {
        let expectedError = PrependTestError.test
        
        var iterator = AsyncStream<String> { $0.finish() }
            .prepend {
                throw expectedError
            }
            .makeAsyncIterator()
        
        do {
            _ = try await iterator.next()
        } catch let error as PrependTestError {
            XCTAssertEqual(error, expectedError)
        } catch {
            XCTFail("Caught unexpected error: \(error)")
        }
        
        let emptyResult = try await iterator.next()
        XCTAssertNil(emptyResult)
    }
}

private enum PrependTestError: Error {
    case test
}
