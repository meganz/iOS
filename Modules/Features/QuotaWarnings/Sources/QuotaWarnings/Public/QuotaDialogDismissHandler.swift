/// Runs the dismiss handlers of a presented quota dialog, in the order they were composed.
/// Also, being a `QuotaDialogDismissHandling` itself, a group of handlers is just another handler.
public final class QuotaDialogDismissHandler: QuotaDialogDismissHandling {
    /// Group of external handlers
    public struct Dependency {
        let audioTearDownHandler: any QuotaDialogDismissHandling

        public init(audioTearDownHandler: any QuotaDialogDismissHandling) {
            self.audioTearDownHandler = audioTearDownHandler
        }
    }

    private let handlers: [any QuotaDialogDismissHandling]

    init(handlers: [any QuotaDialogDismissHandling]) {
        self.handlers = handlers
    }

    public convenience init(kind: QuotaWarningDialogView.Kind, dependency: Dependency) {
        self.init(handlers: QuotaDialogDismissHandlerFactory.handlers(for: kind, dependency: dependency))
    }

    /// Runs every handler in the order it was composed in.
    public func handleDismiss() async {
        for handler in handlers {
            await handler.handleDismiss()
        }
    }
}
