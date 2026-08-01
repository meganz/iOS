/// Decides whether the storage almost-full dialog should be presented for one specific trigger.
///
/// One instance per trigger: it checks that trigger's remaining allowance and the account's current
/// storage state. `recordDialogShown()` must be called only once the dialog was actually presented, so
/// an attempt the caller skips for its own reasons does not spend the allowance.
public protocol StorageAlmostFullDialogUseCaseProtocol: Sendable {
    /// Whether the almost-full dialog should be presented right now for this trigger.
    ///
    /// - Throws: whatever refreshing the account's storage state throws.
    func shouldShowDialog() async throws -> Bool

    /// Records that the dialog was presented.
    func recordDialogShown()
}
