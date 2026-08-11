@testable import MEGAVideoPlayer
import Testing

struct StartupFailureReasonTests {
    @Test
    func playbackError_shouldReportErrCodeOneAndTheMessage() {
        let reason = StartupFailureReason.playbackError(message: "Player item failed with error: boom")

        #expect(reason.errCode == 1)
        #expect(reason.reason == "Player item failed with error: boom")
    }

    @Test(arguments: [nil, "", "   "] as [String?])
    func playbackError_withoutUsableMessage_shouldReportUnknownError(message: String?) {
        let reason = StartupFailureReason.playbackError(message: message)

        #expect(reason.errCode == 1)
        #expect(reason.reason == "Unknown error")
    }

    @Test
    func playbackError_message_shouldBeTrimmedAndCapped() {
        let reason = StartupFailureReason.playbackError(message: "  " + String(repeating: "a", count: 250) + "  ")

        #expect(reason.reason == String(repeating: "a", count: 200))
    }

    @Test
    func noFirstFrame_shouldReportErrCodeZeroAndTheElapsedTime() {
        let reason = StartupFailureReason.noFirstFrame(elapsedMilliseconds: 4200)

        #expect(reason.errCode == 0)
        #expect(reason.reason == "4200")
    }

    @Test
    func noFirstFrame_withoutElapsedTime_shouldReportZero() {
        let reason = StartupFailureReason.noFirstFrame(elapsedMilliseconds: 0)

        #expect(reason.errCode == 0)
        #expect(reason.reason == "0")
    }
}
