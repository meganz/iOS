@testable import MEGA
import MEGADomain
import MEGASwift

public final class MockCallInProgressTimeReporter: CallInProgressTimeReporting {
    private let stream: AsyncStream<TimeInterval>
    private let continuation: AsyncStream<TimeInterval>.Continuation
    
    public init() {
        (stream, continuation) = AsyncStream<TimeInterval>.makeStream()
    }
    
    public func configureCallInProgress(for call: CallEntity) -> AnyAsyncSequence<TimeInterval> {
        stream.eraseToAnyAsyncSequence()
    }
    
    public func yield(timeInterval: TimeInterval) {
        continuation.yield(timeInterval)
    }
}
