import MEGAL10n
import Testing
@testable import Transfer

@Suite("TransferRowState subtitle text")
struct TransferRowStateSubtitleTests {
    @Test func progressText_withArabicLocalization_reordersSizes() {
        let text = TransferRowState.progressText(
            localizedFormat: "[A] من [B]",
            completedSize: "950 م.ب",
            totalSize: "1.88 غ.ب"
        )

        #expect(text == "950 م.ب من 1.88 غ.ب")
    }

    @Test func subtitle_paused_localizesPausedText() {
        let sut = TransferRowState(status: .paused)

        #expect(sut.subtitle.hasSuffix(" · \(Strings.Localizable.paused)"))
    }

    @Test func subtitle_paused_includesProgressButNotSpeed() {
        let sut = TransferRowState(
            direction: .upload,
            status: .paused,
            progress: 0.5,
            transferredBytes: 512,
            totalBytes: 1_024,
            speed: 128
        )

        #expect(sut.subtitle.hasPrefix("↑ 50% · "))
        #expect(sut.subtitle.contains("/s") == false)
    }

    @Test func subtitle_paused_roundsProgress() {
        let sut = TransferRowState(
            status: .paused,
            progress: 2.0 / 3.0
        )

        #expect(sut.subtitle.hasPrefix("↓ 67% · "))
    }
}
