/// Clears the dialog presentation state so the next dialog can be presented.
struct DialogPresentingHandler: QuotaDialogDismissHandling {
    private let presentationState: QuotaDialogPresentationState

    init(presentationState: QuotaDialogPresentationState = .shared) {
        self.presentationState = presentationState
    }

    func handleDismiss() async {
        presentationState.endPresenting()
    }
}
