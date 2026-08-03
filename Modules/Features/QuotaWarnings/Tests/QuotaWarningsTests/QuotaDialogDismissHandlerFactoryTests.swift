@testable import QuotaWarnings
import QuotaWarningsMock
import Testing

/// Every dialog kind, paired with whether it is expected to tear audio playback down on dismiss.
private let audioTearDownExpectations: [(QuotaWarningDialogView.Kind, Bool)] = [
    (.storage(.almostFull), false),
    (.storage(.full(.storageState)), false),
    (.storage(.full(.uploadAttempt)), false),
    (.transfer(.limitedDownload), false),
    (.transfer(.downloadExceeded), false),
    (.transfer(.limitedStreaming), false),
    (.transfer(.streamingExceeded), true)
]

private let allKinds: [QuotaWarningDialogView.Kind] = audioTearDownExpectations.map { $0.0 }

@MainActor
@Suite("QuotaDialogDismissHandlerFactory")
struct QuotaDialogDismissHandlerFactoryTests {

    @Test("Every kind resets the presenting state", arguments: allKinds)
    func alwaysResetsPresentingState(kind: QuotaWarningDialogView.Kind) {
        let handlers = QuotaDialogDismissHandlerFactory.handlers(
            for: kind,
            dependency: .init(audioTearDownHandler: MockQuotaDialogDismissHandler())
        )

        #expect(handlers.contains { $0 is DialogPresentingHandler })
    }

    @Test("Only exceeded streaming tears audio playback down", arguments: audioTearDownExpectations)
    func tearsAudioDownForExceededStreamingOnly(kind: QuotaWarningDialogView.Kind, tearsAudioDown: Bool) {
        let audioTearDownHandler = MockQuotaDialogDismissHandler()
        let handlers = QuotaDialogDismissHandlerFactory.handlers(
            for: kind,
            dependency: .init(audioTearDownHandler: audioTearDownHandler)
        )

        #expect(handlers.contains { $0 is MockQuotaDialogDismissHandler } == tearsAudioDown)
    }
}
