import MEGAAppPresentation

public final class MockOfflineActionGuard: OfflineActionGuarding, @unchecked Sendable {
    private let allowsAction: Bool
    public private(set) var allowsActionRequiringConnectionCallCount = 0

    public init(allowsAction: Bool = true) {
        self.allowsAction = allowsAction
    }

    public func allowsActionRequiringConnection() -> Bool {
        allowsActionRequiringConnectionCallCount += 1
        return allowsAction
    }
}
