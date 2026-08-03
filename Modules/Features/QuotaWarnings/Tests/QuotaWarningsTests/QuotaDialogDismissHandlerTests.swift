@testable import QuotaWarnings
import QuotaWarningsMock
import Testing

@MainActor
@Suite("QuotaDialogDismissHandler")
struct QuotaDialogDismissHandlerTests {

    /// Collects the handlers that ran, in order, so composition can be asserted.
    @MainActor final class Recorder {
        private(set) var handledIdentifiers: [String] = []

        func record(_ identifier: String) {
            handledIdentifiers.append(identifier)
        }
    }

    @Test("Runs every handler in the order they were composed in")
    func runsHandlersInComposedOrder() async {
        let recorder = Recorder()
        let sut = QuotaDialogDismissHandler(handlers: [
            MockQuotaDialogDismissHandler { recorder.record("first") },
            MockQuotaDialogDismissHandler { recorder.record("second") },
            MockQuotaDialogDismissHandler { recorder.record("third") }
        ])

        await sut.handleDismiss()

        #expect(recorder.handledIdentifiers == ["first", "second", "third"])
    }

    @Test("Runs each handler exactly once")
    func runsEachHandlerOnce() async {
        let handler = MockQuotaDialogDismissHandler()
        let sut = QuotaDialogDismissHandler(handlers: [handler])

        await sut.handleDismiss()

        #expect(handler.handleDismissCallCount == 1)
    }

    @Test("Handles an empty handler list")
    func handlesEmptyHandlerList() async {
        let sut = QuotaDialogDismissHandler(handlers: [])

        await sut.handleDismiss()
    }
}
