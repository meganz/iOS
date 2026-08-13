import MEGAAppPresentation
import MEGADomain

public struct MockOfflineFileOpenGuard: OfflineFileOpenGuarding {
    public var isActive: Bool
    public var shouldBlock: Bool

    public init(isActive: Bool = true, shouldBlock: Bool = false) {
        self.isActive = isActive
        self.shouldBlock = shouldBlock
    }

    /// Mirrors the real guard: nothing is blocked while the guard is inactive.
    public func shouldBlockOpening(_ node: NodeEntity) -> Bool {
        isActive && shouldBlock
    }
}
