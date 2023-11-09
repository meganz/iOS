import SwiftUI

public struct ThrowingTaskModifier: ViewModifier {
    private var priority: TaskPriority
    private var action: @Sendable () async throws -> Void

    public init(
        priority: TaskPriority,
        action: @escaping @Sendable () async throws -> Void
    ) {
        self.priority = priority
        self.action = action
    }

    @State private var task: Task<Void, any Error>?
    
    private func cancelTask() {
        task?.cancel()
        task = nil
    }

    public func body(content: Content) -> some View {
        content
            .task(priority: priority) {
                do {
                    try await action()
                } catch {
                    debugPrint("Error occurred: \(error)")
                    cancelTask()
                }
            }
    }
}

public extension View {
    
    /// Asynchronous Throwing Task to Perform on the View
    ///
    /// This function provides a way to execute asynchronous throwing tasks on a SwiftUI view
    ///
    /// - Parameter priority: The priority at which the task should be executed. Default is `TaskPriority.userInitiated`.
    /// - Parameter action: A throwing asynchronous closure that will be performed as a task on the view.
    ///
    /// - Returns: A modified view that will execute the provided throwing action asynchronously.
    ///
    /// - Note: This modifier uses the native `task(priority:_:)` modifier
    ///         to execute the provided action.
    func throwingTask(
        priority: TaskPriority = .userInitiated,
        @_inheritActorContext _ action: @escaping @Sendable () async throws -> Void
    ) -> some View {
        self.modifier(ThrowingTaskModifier(priority: priority, action: action))
    }
}
