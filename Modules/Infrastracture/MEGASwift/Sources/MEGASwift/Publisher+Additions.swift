import Combine

public extension Publisher {
    func combinePrevious(_ initialResult: Output) -> AnyPublisher<(previous: Output, current: Output), Failure> {
        scan((initialResult, initialResult)) {
            ($0.1, $1)
        }
        .eraseToAnyPublisher()
    }
    
    /// Publishes elements only after a specified time interval elapses between events. Except for the first element, that will publish immediately in to the downstream.
    ///
    /// Refer to the Publisher/debounce(for:scheduler:options: to understand its functionailty
    /// - Parameters:
    ///   - dueTime: The time the publisher should wait before publishing an element.
    ///   - scheduler: The scheduler on which this publisher delivers elements
    ///   - options: Scheduler options that customize this publisher’s delivery of elements.
    /// - Returns: A publisher that publishes the first event immediately and then all future events are emitted only after a specified time elapses.
    func debounceImmediate<S>(for dueTime: S.SchedulerTimeType.Stride, scheduler: S, options: S.SchedulerOptions? = nil) -> AnyPublisher<Output, Failure> where S: Scheduler {
        Publishers
            .Merge(
                first(),
                dropFirst().debounce(for: dueTime, scheduler: scheduler))
            .eraseToAnyPublisher()
    }
}
