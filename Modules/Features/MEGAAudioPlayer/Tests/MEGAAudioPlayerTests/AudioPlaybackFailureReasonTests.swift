@testable import MEGAAudioPlayer
import Testing

@Suite("AudioPlaybackFailureReason event reason")
struct AudioPlaybackFailureReasonTests {
    @Test
    func itemFailed_shouldCarryTheItemErrorText() {
        let reason = AudioPlaybackFailureReason.itemFailed(reason: "The operation could not be completed")

        #expect(reason.eventReason == "itemFailed:The operation could not be completed")
    }

    @Test(arguments: [nil, "", "   "] as [String?])
    func itemFailed_withoutUsableText_shouldFallBackToUnknownError(text: String?) {
        let reason = AudioPlaybackFailureReason.itemFailed(reason: text)

        #expect(reason.eventReason == "itemFailed:Unknown error")
    }

    @Test
    func itemFailed_text_shouldBeTrimmedAndCapped() {
        let reason = AudioPlaybackFailureReason.itemFailed(reason: "  " + String(repeating: "a", count: 250) + "  ")

        #expect(reason.eventReason == "itemFailed:" + String(repeating: "a", count: 200))
    }

    @Test
    func reasonsWithoutDetail_shouldReportTheirOwnName() {
        #expect(AudioPlaybackFailureReason.urlUnresolved.eventReason == "urlUnresolved")
        #expect(AudioPlaybackFailureReason.takenDown.eventReason == "takenDown")
        #expect(AudioPlaybackFailureReason.queueEmpty.eventReason == "queueEmpty")
    }
}
