import Foundation

public protocol AsyncQueueProtocol: Actor {
    associatedtype Element: Sendable
    
    /// The current number of elements in the queue.
    var count: Int { get }
    
    /// A Boolean value indicating whether the queue is empty.
    var isEmpty: Bool { get }
    
    /// Inserts the specified element at the end of the queue.
    ///
    /// If the queue is full, this method does nothing and returns `false`.
    ///
    /// - Parameter element: The element to insert.
    /// - Returns: `true` if the element was successfully inserted; otherwise, `false`.
    func enqueue(_ element: Element) -> Bool
    
    /// Removes and returns the element at the front of the queue.
    ///
    /// If the queue is empty, this method returns `nil`.
    ///
    /// - Returns: The element that was removed, or `nil` if the queue was empty.
    func dequeue() -> Element?
    
    /// Returns the item at the front of the queue without removing it.
    ///
    /// If the queue is empty, this method returns `nil`.
    func peek() -> Element?
    
    /// Inserts the specified element at the end of the specified queue asynchronously.
    ///
    /// - Parameters:
    ///   - element: The element to insert.
    ///   - queue: The queue where the element will be inserted.
    ///
    /// This method uses a `Task` to ensure the enqueue operation is performed
    /// asynchronously, respecting the actor's thread-safety rules.
    static func enqueue(_ element: Element, into queue: Self)
}

public extension AsyncQueueProtocol {
    static func enqueue(_ element: Element, into queue: Self) {
        Task { await queue.enqueue(element) }
    }
}

// MARK: - Circular Queue

public protocol AsyncCircularQueueProtocol: AsyncQueueProtocol {
    /// The maximum number of elements the queue can hold.
    var capacity: Int { get }
    
    /// A Boolean value indicating whether the queue is full.
    var isFull: Bool { get }
}

// MARK: Circular Queue Implementation

/// This queue follows the FIFO (First In, First Out) principle. When the queue is full, depending on the `allowEnqueueOverflow` parameter, it either denies any new enqueue requests or automatically dequeues the oldest item to make space for the new item.
public actor AsyncCircularQueue<Element: Sendable>: AsyncCircularQueueProtocol {
    private var elements: [Element?]
    private var indexOf: (head: Int, tail: Int) = (.zero, .zero)
    private var nextInsertIndex: Int { (indexOf.tail + 1) % elements.count }
    
    private let allowEnqueueOverflow: Bool
    public let capacity: Int
    
    public var isFull: Bool { nextInsertIndex == indexOf.head }
    
    public var isEmpty: Bool { indexOf.head == indexOf.tail }
    
    public var count: Int {
        let diff = indexOf.tail - indexOf.head
        return (diff < 0) ? diff + elements.count : diff
    }
    
    /// Creates a new instance of `AsyncCircularQueue` with the specified capacity and enqueue overflow behaviour.
    ///
    /// - Parameters:
    ///   - capacity: The maximum number of elements the queue can hold.
    ///   - allowEnqueueOverflow: A Boolean value indicating whether the queue should automatically dequeue the oldest item when it's full and a new item is enqueued. The default value is `false`.
    public init(capacity: Int, allowEnqueueOverflow: Bool = false) {
        precondition(capacity < Int.max, "If your maximum capacity is Int.max, you'd be better off using a standard Queue data structure")
        self.capacity = capacity
        self.elements = .init(repeating: nil, count: capacity + 1)
        self.allowEnqueueOverflow = allowEnqueueOverflow
    }
    
    public func peek() -> Element? {
        elements[indexOf.head]
    }
    
    @discardableResult
    public func enqueue(_ element: Element) -> Bool {
        if isFull && !allowEnqueueOverflow { return false }
        let insertIndex = isFull ? indexOf.head : indexOf.tail
        elements[insertIndex] = element
        if isFull {
            indexOf.head = (indexOf.head + 1) % elements.count
        }
        indexOf.tail = nextInsertIndex
        return true
    }
    
    @discardableResult
    public func dequeue() -> Element? {
        if isEmpty { return nil }
        let element = elements[indexOf.head]
        indexOf.head = (indexOf.head + 1) % elements.count
        return element
    }
}
