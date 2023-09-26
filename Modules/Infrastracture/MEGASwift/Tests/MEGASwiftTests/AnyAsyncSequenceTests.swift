import MEGASwift
import XCTest

final class AnyAsyncSequenceTests: XCTestCase {
    func testAnyAsyncSequence_noTransformationAndUnboundedBuffer() async throws {
        let stream = AsyncStream<Int>(Int.self) { continuation in
            Task.detached {
                for i in 0..<5 {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    continuation.yield(i)
                }
                continuation.finish()
            }
        }
        
        let sequence = stream.eraseToAnyAsyncSequence()
        var result = [Int]()
        for await item in sequence {
            result.append(item)
        }
        
        XCTAssertEqual(result, [0, 1, 2, 3, 4])
    }
    
    func testAnyAsyncSequence_noTransformationAndHasBuffer() async throws {
        let stream = AsyncStream<Int>(Int.self, bufferingPolicy: .bufferingNewest(2)) { continuation in
                for i in 0..<5 {
                    continuation.yield(i)
                }
                continuation.finish()
        }
        
        let sequence = stream.eraseToAnyAsyncSequence()
        var result = [Int]()
        for await item in sequence {
            result.append(item)
        }
        
        XCTAssertEqual(result, [3, 4])
    }
    
    func testAnyAsyncSequence_hasTransformations() async throws {
        let stream = AsyncStream<Int>(Int.self) { continuation in
            Task.detached {
                for i in 0..<10 {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    continuation.yield(i)
                }
                continuation.finish()
            }
        }.filter {
            $0 % 2 == 0
        }.map {
            $0 + 3
        }.drop {
            $0 < 9
        }
        
        let sequence = stream.eraseToAnyAsyncSequence()
        var result = [Int]()
        for await item in sequence {
            result.append(item)
        }
        
        XCTAssertEqual(result, [9, 11])
    }
}
