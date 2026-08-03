/// Tracks whether a quota dialog is currently on screen, so a second one is never stacked on top.
///
/// Presentation claims the slot with `beginPresenting()`, dismissal releases it through `DialogPresentingHandler`.
@MainActor public final class QuotaDialogPresentationState {
    public static let shared = QuotaDialogPresentationState()

    public private(set) var isPresenting = false

    init() {}

    /// Claims the single quota dialog slot.
    /// - Returns: `false` when a dialog is already on screen, in which case nothing was claimed.
    public func beginPresenting() -> Bool {
        guard !isPresenting else { return false }

        isPresenting = true
        return true
    }

    func endPresenting() {
        isPresenting = false
    }
}
