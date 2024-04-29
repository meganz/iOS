public extension Array where Element == Task<Void, any Error> {
    
    ///  Create and store Task into this Sequence
    /// - Parameter action: Async block to run operation
    mutating func appendTask(_ action: @escaping @Sendable () async -> Void) {
        append(task(for: action))
    }
    
    /// Cancel and remove all Tasks in this Sequence
    mutating func cancelTasks() {
        cancelAllTasks()
        removeAll()
    }
}

public extension Set where Element == Task<Void, any Error> {
    
    ///  Create and store Task into this Sequence
    /// - Parameter action: Async block to run operation
    mutating func appendTask(_ action: @escaping @Sendable () async -> Void) {
        insert(task(for: action))
    }
    
    /// Cancel and remove all Tasks in this Sequence
    mutating func cancelTasks() {
        cancelAllTasks()
        removeAll()
    }
}

fileprivate extension Sequence where Element == Task<Void, any Error> {
    
    func task(for action: @escaping @Sendable () async -> Void) -> Task<Void, any Error> {
        Task { await action() }
    }
    
    func cancelAllTasks() {
        forEach { $0.cancel() }
    }
}
