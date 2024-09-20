@testable import MEGA

struct MockTimerSequenceFactory: TimerSequenceProtocol {
    func timerSequenceWithInterval(_ interval: TimeInterval) -> AsyncStream<Date> {
        let (stream, _) = AsyncStream
            .makeStream(of: Date.self)
        return stream
    }
}
