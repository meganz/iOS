import Foundation

/// A property wrapper that ensures thread-safe access to a provided value.
///
/// `Atomic` can be used to make properties thread-safe, by guaranteeing that
/// reading and/or writing to the property will be synchronized and not
/// interfere with each other in a concurrent environment.
///
/// This wrapper requires that the wrapped value conforms to the `Sendable`
/// protocol, ensuring it can be safely used in a concurrent code.
///
/// Example:
/// ```swift
/// @Atomic var counter: Int = 0
///
/// $counter.mutate { $0 += 1 }  // Thread-safe write
/// let value = counter          // Thread-safe read
/// ```
@propertyWrapper
public final class Atomic<T: Sendable> {
    
    /// The internal `DispatchQueue` used for synchronization.
    private let _queue: DispatchQueue
    
    /// The actual value being wrapped.
    private var _value: T
    
    /// Returns the current instance of `Atomic`, allowing access to the wrapper's methods and properties.
    public var projectedValue: Atomic<T> {
        return self
    }
    
    /// The thread-safe wrapped value.
    public var wrappedValue: T {
        _queue.sync {
            _value
        }
    }
    
    /// Creates an `Atomic` property wrapper with an initial wrapped value and optional dispatch queue.
    ///
    /// - Parameters:
    ///   - wrappedValue: The initial value for the wrapped property.
    ///   - queue: The `DispatchQueue` to use for synchronization. If not provided, a new concurrent queue is created.
    public init(wrappedValue value: T, queue: DispatchQueue = DispatchQueue(label: "com.mega.concurrentqueue", attributes: .concurrent)) {
        _value = value
        _queue = queue
    }
    
    /// Safely mutates the wrapped value.
    ///
    /// - Parameter mutation: A closure that accepts an `inout` parameter of the wrapped value type, which can be mutated safely.
    public func mutate(_ mutation: @escaping (inout T) -> Void) {
        _queue.async(flags: .barrier) {
            mutation(&self._value)
        }
    }
}
