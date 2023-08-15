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

public extension View {
    /// Asynchronous task to perform on the view
    ///
    /// iOS 15 and later will perform the task before view appears. See `task(priority:_:)` for more info.
    ///
    /// iOS 15 and lower it will create the task `onAppear` and cancel it `onDisappear`.
    ///
    /// - Parameter priority The task priority to use when creating the asynchronous task. The default priority is userInitiated.
    /// - Parameter action A closure that SwiftUI calls as an asynchronous task
    @available(iOS, obsoleted: 15.0, message: "task(priority:_:) is available on iOS 15.")
    func taskForiOS14(
        priority: TaskPriority = .userInitiated,
        @_inheritActorContext _ action: @escaping @Sendable () async -> Void
    ) -> some View {
        modifier(TaskModifier(priority: priority, action: action))
    }
}
