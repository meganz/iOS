import Combine
import Foundation

/// A struct that batches incoming values over a specified interval of time
/// and emits them as an array at the end of each interval.
///
/// The `BatchingPublisher` collects values on a given dispatch queue and
/// publishes them as a batch at regular intervals.
///
/// - Parameters:
///   - interval: The interval in seconds at which the values will be batched and emitted.
///
///   /// Example usage:
/// ```swift
/// let batchingPublisher = BatchingPublisher<String>(
///     interval: 2
/// )
///
/// // Subscribe to the publisher
/// let cancellable = batchingPublisher.publisher
///     .sink(receiveValue: { values in
///         print("Received batch: \(values)")
///     })
///
/// // Append values
/// batchingPublisher.append("Value 1")
/// batchingPublisher.append("Value 2")
/// // After 2 seconds, will print: "Received batch: [Value 1, Value 2]"
/// ```
public struct BatchingPublisher<T> {
    // The dispatch queue on which the values will be collected and emitted
    private let queue = DispatchQueue(label: "BatchingPublisherQueue")

    // The interval in seconds at which the values will be batched and emitted
    private let interval: Int

    // The PassthroughSubject that acts as the source publisher for incoming values
    private let sourcePublisher = PassthroughSubject<T, Never>()

    public init(interval: Int) {
        self.interval = interval
    }

    // The publisher that emits batches of collected values at the specified interval
    public var publisher: AnyPublisher<[T], Never> {
        sourcePublisher
            .collect(.byTime(queue, .seconds(interval)))
            .eraseToAnyPublisher()
    }

    // Appends a new value to the source publisher
    public func append(_ value: T) {
        sourcePublisher.send(value)
    }
}
