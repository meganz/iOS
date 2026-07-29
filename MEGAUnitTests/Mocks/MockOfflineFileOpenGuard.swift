@testable import MEGA
import MEGADomain

struct MockOfflineFileOpenGuard: OfflineFileOpenGuarding {
    var isActive = true
    var shouldBlock = false

    /// Mirrors the real guard: nothing is blocked while the guard is inactive.
    func shouldBlockOpening(_ node: NodeEntity) -> Bool {
        isActive && shouldBlock
    }
}
