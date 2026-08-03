@testable import QuotaWarnings
import Testing

@MainActor
@Suite("DialogPresentingHandler")
struct DialogPresentingHandlerTests {

    @Test("Releases the presenting slot so the next dialog can be shown")
    func releasesPresentingSlot() async {
        let presentationState = QuotaDialogPresentationState()
        #expect(presentationState.beginPresenting())
        let sut = DialogPresentingHandler(presentationState: presentationState)

        await sut.handleDismiss()

        #expect(presentationState.isPresenting == false)
        #expect(presentationState.beginPresenting())
    }

    @Test("Leaves an already cleared flag untouched")
    func keepsClearedFlagCleared() async {
        let presentationState = QuotaDialogPresentationState()
        let sut = DialogPresentingHandler(presentationState: presentationState)

        await sut.handleDismiss()

        #expect(presentationState.isPresenting == false)
    }
}
