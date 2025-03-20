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

public extension Collection where Element: Sendable, Index == Int {
    func taskGroup(maxConcurrentTasks: Int = 3, operation: @Sendable @escaping (Element) async -> Void) async {
        await withTaskGroup(of: Void.self) { taskGroup in
            let maxConcurrentTasks = Swift.min(maxConcurrentTasks, count)
            for item in self[0..<maxConcurrentTasks] {
                guard !Task.isCancelled else { break }
                taskGroup.addTask { await operation(item) }
            }
            
            var nextTaskIndex = maxConcurrentTasks
            for await _ in taskGroup where nextTaskIndex < count {
                guard !Task.isCancelled else { break }
                let item = self[nextTaskIndex]
                nextTaskIndex += 1
                taskGroup.addTask { await operation(item) }
            }
        }
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
