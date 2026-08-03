/// Composes the handlers to run when a quota dialog of a given kind is dismissed.
@MainActor enum QuotaDialogDismissHandlerFactory {
    static func handlers(
        for kind: QuotaWarningDialogView.Kind,
        dependency: QuotaDialogDismissHandler.Dependency
    ) -> [any QuotaDialogDismissHandling] {
        requiredHandlers + additionalHandlers(for: kind, dependency: dependency)
    }

    /// Run for every kind, so a kind added later can never accidentally skip them.
    /// Kept first so releasing the presentation slot can never be blocked by an additional handler that stalls.
    private static var requiredHandlers: [any QuotaDialogDismissHandling] {
        [DialogPresentingHandler()]
    }

    private static func additionalHandlers(
        for kind: QuotaWarningDialogView.Kind,
        dependency: QuotaDialogDismissHandler.Dependency
    ) -> [any QuotaDialogDismissHandling] {
        switch kind {
        case .transfer(.streamingExceeded):
            [dependency.audioTearDownHandler]
        default:
            []
        }
    }
}
