/// Specify what the subscription page should behave when a purchase completes successfully.
public enum PurchaseCompleteBehavior: Sendable {
    /// the subscription page dismisses itself, the right default for a standalone modal presentation.
    case dismiss
    /// the subscription page does not dismiss itself and runs the given action instead/
    /// (e.g. dismissing the navigation controller that hosts a pushed subscription page) without a pop-then-dismiss flicker
    case perform(@MainActor () -> Void)
}
