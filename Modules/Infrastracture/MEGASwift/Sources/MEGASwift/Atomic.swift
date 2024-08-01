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
///
/// Note:
/// Must avoid heavy operation within mutation closure
@propertyWrapper
public final class Atomic<T: Sendable>: @unchecked Sendable {
    
    /// The internal `NSLock` used for synchronization.
    private let lock: NSLock = NSLock()
    
    /// The actual value being wrapped.
    private var value: T
    
    /// Returns the current instance of `Atomic`, allowing access to the wrapper's methods and properties.
    public var projectedValue: Atomic<T> {
        return self
    }
    
    /// The thread-safe wrapped value.
    public var wrappedValue: T {
        lock.withLock { value }
    }
    
    /// Creates an `Atomic` property wrapper with an initial wrapped value
    ///
    /// - Parameters:
    ///   - wrappedValue: The initial value for the wrapped property.
    public init(wrappedValue: T) {
        value = wrappedValue
    }
    
    /// Safely mutates the wrapped value.
    ///
    /// - Parameter mutation: A closure that accepts an `inout` parameter of the wrapped value type, which can be mutated safely.
    ///  Should not perform heavy operation within the clousure, otherwise calling thread will be blocked for too long.
    public func mutate(_ mutation: (inout T) -> Void) {
        lock.withLock { mutation(&self.value) }
    }
}

/// Abstraction of DispatchQueue to enable testability for `Atomic`
public protocol AtomicDispatchQueueProtocol {
    func async(flags: DispatchWorkItemFlags, execute work: @escaping @Sendable @convention(block) () -> Void)
    func sync<T>(execute work: () throws -> T) rethrows -> T
}

extension DispatchQueue: AtomicDispatchQueueProtocol {
    public func async(flags: DispatchWorkItemFlags, execute work: @escaping @Sendable @convention(block) () -> Void) {
        async(group: nil, qos: qos, flags: flags, execute: work)
    }
}
