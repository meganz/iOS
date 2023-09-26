import MEGASwift
import XCTest

final class AnyAsyncThrowingSequenceTests: XCTestCase {
    struct SequenceError: Error {}
    
    func testAnyAsyncThrowingSequence_noTransformationAndUnboundedBuffer() async throws {
        let stream = AsyncThrowingStream<Int, Error>(Int.self) { continuation in
            Task.detached {
                for i in 1..<100 {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    if i % 5 == 0 {
                        continuation.finish(throwing: SequenceError())
                        return
                    } else {
                        continuation.yield(i)
                    }
                }
                continuation.finish()
            }
        }
        
        let sequence = stream.eraseToAnyAsyncThrowingSequence()
        var result = [Int]()
        do {
            for try await item in sequence {
                result.append(item)
            }
        } catch {
            XCTAssertTrue(error is SequenceError)
        }
        
        XCTAssertEqual(result, [1, 2, 3, 4])
    }
    
    func testAnyAsyncThrowingSequence_noTransformationAndHasBuffer() async throws {
        let stream = AsyncThrowingStream<Int, Error>(Int.self, bufferingPolicy: .bufferingNewest(2)) { continuation in
            for i in 1..<100 {
                if i % 5 == 0 {
                    continuation.finish(throwing: SequenceError())
                    return
                } else {
                    continuation.yield(i)
                }
            }
            continuation.finish()
        }
        
        let sequence = stream.eraseToAnyAsyncThrowingSequence()
        var result = [Int]()
        do {
            for try await item in sequence {
                result.append(item)
            }
        } catch {
            XCTAssertTrue(error is SequenceError)
        }
        
        XCTAssertEqual(result, [3, 4])
    }
    
    func testAnyAsyncThrowingSequence_hasTransformations() async throws {
        @Sendable func makeSequence(_ value: Int) -> AnyAsyncThrowingSequence<Int, Error> {
            AsyncThrowingStream<Int, Error>(Int.self) { continuation in
                Task.detached {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    
                    for i in 1..<value {
                        if i % 5 == 0 {
                            continuation.finish(throwing: SequenceError())
                            return
                        } else {
                            continuation.yield(i)
                        }
                    }
                    continuation.finish()
                }
            }
            .filter {
                $0 < value
            }
            .eraseToAnyAsyncThrowingSequence()
        }
        
        let stream = makeSequence(11).flatMap { makeSequence($0) }
        
        let sequence = stream.eraseToAnyAsyncThrowingSequence()
        var result = [Int]()
        do {
            for try await item in sequence {
                result.append(item)
            }
        } catch {
            XCTAssertTrue(error is SequenceError)
        }
        
        XCTAssertEqual(result, [1, 1, 2, 1, 2, 3])
    }
}
