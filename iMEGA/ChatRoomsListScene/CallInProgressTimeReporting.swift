import MEGADomain
import MEGASwift

protocol CallInProgressTimeReporting: AnyObject {
    func configureCallInProgress(for call: CallEntity) -> AnyAsyncSequence<TimeInterval>
}

final class CallInProgressTimeReporter: CallInProgressTimeReporting {
    func configureCallInProgress(for call: CallEntity) -> AnyAsyncSequence<TimeInterval> {
        guard call.duration > 0 else {
            return EmptyAsyncSequence().eraseToAnyAsyncSequence()
        }
        
        let callDurationTotal = TimeInterval(call.duration)
        let callDurationCapturedTime = Date().timeIntervalSince1970
        
        return Timer
            .publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .map { _ in
                Date().timeIntervalSince1970 - callDurationCapturedTime + callDurationTotal
            }
            .values
            .eraseToAnyAsyncSequence()
    }
}
