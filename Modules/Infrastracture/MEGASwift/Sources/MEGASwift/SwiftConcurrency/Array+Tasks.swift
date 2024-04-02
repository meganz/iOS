public extension Array where Element == Task<Void, any Error> {
    
    mutating func appendTask(_ action: @escaping @Sendable () async -> Void) {
        append(Task { await action() })
    }
    
    mutating func cancelTasks() {
        forEach { $0.cancel() }
        removeAll()
    }
}
