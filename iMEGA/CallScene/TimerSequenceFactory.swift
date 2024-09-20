import Foundation

public protocol TimerSequenceProtocol: Sendable {
    func timerSequenceWithInterval(_ interval: TimeInterval) -> AsyncStream<Date>
}

public struct TimerSequenceFactory: TimerSequenceProtocol {
    public func timerSequenceWithInterval(_ interval: TimeInterval) -> AsyncStream<Date> {
        let publisher = Timer.publish(every: interval, on: .main, in: .common).autoconnect()
        
        return AsyncStream { continuation in
            let cancellable = publisher.sink { date in
                continuation.yield(date)
            }
            
            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }
}
