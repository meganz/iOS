import QuotaWarnings

public final class MockQuotaDialogDismissHandler: QuotaDialogDismissHandling {
    public private(set) var handleDismissCallCount = 0

    private let onHandleDismiss: (@MainActor () -> Void)?

    public init(onHandleDismiss: (@MainActor () -> Void)? = nil) {
        self.onHandleDismiss = onHandleDismiss
    }

    public func handleDismiss() async {
        handleDismissCallCount += 1
        onHandleDismiss?()
    }
}
