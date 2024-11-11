import Foundation

public extension TaskGroup {
    
    /// Adds a child task to the group, unless the group has been canceled. Tasks will stop adding to the group immediately if cancelled via cooperative cancellation.
    ///
    /// - Parameters:
    ///   - sequence: Sequence of elements to apply task action on.
    ///   - priority: The priority of the operation task.
    ///     Omit this parameter or pass `.unspecified`
    ///     to set the child task's priority to the priority of the group.
    ///   - operation: The operation with element provided in the sequence to execute as part of the task group.
    mutating func addTasksUnlessCancelled<Element: Sendable>(for sequence: some Sequence<Element>, priority: TaskPriority? = nil, operation: @escaping @Sendable (Element) async -> ChildTaskResult) {
        for element in sequence {
            guard addTaskUnlessCancelled(priority: priority, operation: { @Sendable in await operation(element) }) else {
                break
            }
        }
    }
}

public extension ThrowingTaskGroup {
    
    /// Adds a child task to the group, unless the group has been canceled. Tasks will stop adding to the group immediately if cancelled via cooperative cancellation.
    ///
    /// - Parameters:
    ///   - sequence: Sequence of elements to apply task action on.
    ///   - priority: The priority of the operation task.
    ///     Omit this parameter or pass `.unspecified`
    ///     to set the child task's priority to the priority of the group.
    ///   - operation: The operation with element provided in the sequence to execute as part of the task group.
    mutating func addTasksUnlessCancelled<Element: Sendable>(for sequence: some Sequence<Element>, priority: TaskPriority? = nil, operation: @escaping @Sendable (Element) async throws -> ChildTaskResult) {
        for element in sequence {
            guard addTaskUnlessCancelled(priority: priority, operation: { @Sendable in try await operation(element) }) else {
                break
            }
        }
    }
}
