/// A single, self contained side effect to run when a quota dialog is dismissed.
@MainActor public protocol QuotaDialogDismissHandling {
    func handleDismiss() async
}

public extension QuotaDialogDismissHandling {
    func dismiss() {
        Task { await handleDismiss() }
    }
}
