@testable import MEGA

final class MockOfflineActionGuard: OfflineActionGuarding, @unchecked Sendable {
    private let allowsAction: Bool
    private(set) var allowsActionRequiringConnectionCallCount = 0

    init(allowsAction: Bool = true) {
        self.allowsAction = allowsAction
    }

    func allowsActionRequiringConnection() -> Bool {
        allowsActionRequiringConnectionCallCount += 1
        return allowsAction
    }
}
