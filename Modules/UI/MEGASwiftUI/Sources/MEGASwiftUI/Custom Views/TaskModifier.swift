import SwiftUI

public struct TaskModifier: ViewModifier {
    private var priority: TaskPriority
    private var action: @Sendable () async -> Void

    public init(
        priority: TaskPriority,
        action: @escaping @Sendable () async -> Void
    ) {
        self.priority = priority
        self.action = action
    }

    @State private var task: Task<Void, Never>?

    public func body(content: Content) -> some View {
        if #available(iOS 15.0, *) {
            content
                .task(priority: priority, action)
        } else {
            content
                .onAppear {
                    task = Task(priority: priority) {
                        await action()
                    }
                }
                .onDisappear {
                    task?.cancel()
                    task = nil
                }
        }
    }
}

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
        if #available(iOS 15.0, *) {
            content
                .task(priority: priority) {
                    do {
                        try await action()
                    } catch {
                        debugPrint("Error occurred: \(error)")
                        cancelTask()
                    }
                }
        } else {
            content
                .onAppear {
                    task = Task(priority: priority) {
                        do {
                            try await action()
                        } catch {
                            debugPrint("Error occurred: \(error)")
                            cancelTask()
                        }
                    }
                }
                .onDisappear {
                    cancelTask()
                }
        }
    }
}

public extension View {
    
    /// Asynchronous Task to Perform on the View (iOS 14 Compatibility)
    ///
    /// This function offers a way to execute asynchronous tasks on a SwiftUI view,
    /// especially when targeting iOS 14 and lower versions that lack the built-in `task(priority:_:)` modifier.
    ///
    /// - Parameter priority: The priority at which the task should be executed. Default is `TaskPriority.userInitiated`.
    /// - Parameter action: An asynchronous closure that will be performed as a task on the view.
    ///
    /// - Returns: A modified view that will execute the provided action asynchronously.
    ///
    /// - Note: On iOS 15 and later, this modifier is obsolete and has no effect due to the availability
    ///         of the native `task(priority:_:)` modifier. On iOS 14 and lower, it creates a custom `Task`
    ///         using `onAppear` and `onDisappear` modifiers to handle the asynchronous action.
    @available(iOS, obsoleted: 15.0, message: "task(priority:_:) is available on iOS 15.")
    func taskForiOS14(
        priority: TaskPriority = .userInitiated,
        @_inheritActorContext _ action: @escaping @Sendable () async -> Void
    ) -> some View {
        modifier(TaskModifier(priority: priority, action: action))
    }
    
    /// Asynchronous Throwing Task to Perform on the View (iOS 14 Compatibility)
    ///
    /// This function provides a way to execute asynchronous throwing tasks on a SwiftUI view,
    /// especially when targeting iOS 14 and lower versions that lack the built-in `task(priority:_:)` modifier.
    ///
    /// - Parameter priority: The priority at which the task should be executed. Default is `TaskPriority.userInitiated`.
    /// - Parameter action: A throwing asynchronous closure that will be performed as a task on the view.
    ///
    /// - Returns: A modified view that will execute the provided throwing action asynchronously.
    ///
    /// - Note: On iOS 15 and later, this modifier uses the native `task(priority:_:)` modifier
    ///         to execute the provided action. On iOS 14 and lower, it creates a custom `Task`
    ///         using `onAppear` and `onDisappear` modifiers to handle the asynchronous action.
    ///         If the action throws an error, the task will be cancelled.
    @available(iOS, obsoleted: 15.0, message: "task(priority:_:) is available on iOS 15.")
    func throwingTaskForiOS14(
        priority: TaskPriority = .userInitiated,
        @_inheritActorContext _ action: @escaping @Sendable () async throws -> Void
    ) -> some View {
        self.modifier(ThrowingTaskModifier(priority: priority, action: action))
    }
}
