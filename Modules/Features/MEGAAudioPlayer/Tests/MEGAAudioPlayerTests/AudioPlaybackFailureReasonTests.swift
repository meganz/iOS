import Foundation
@testable import MEGAAudioPlayer
import Testing

@Suite("AudioPlaybackFailureReason event reason")
struct AudioPlaybackFailureReasonTests {
    @Test
    func itemFailed_shouldCarryTheErrorCodesRatherThanItsText() {
        let underlying = NSError(domain: NSOSStatusErrorDomain, code: -12938)
        let error = NSError(
            domain: "AVFoundationErrorDomain",
            code: -11800,
            userInfo: [
                NSLocalizedDescriptionKey: "The operation could not be completed",
                NSUnderlyingErrorKey: underlying
            ]
        )

        let reason = itemFailed(error)

        #expect(reason.eventReason == "itemFailed:AVFoundationErrorDomain:-11800|u=NSOSStatusErrorDomain:-12938|airplay=0|t=0/-")
    }

    @Test
    func itemFailed_withoutAnError_shouldSayNone() {
        #expect(itemFailed(nil).eventReason == "itemFailed:none|airplay=0|t=0/-")
    }

    @Test
    func itemFailed_shouldReportAirPlayAndWherePlaybackWas() {
        let reason = itemFailed(nil, isAirPlayActive: true, position: 37.8, duration: 245.2)

        #expect(reason.eventReason == "itemFailed:none|airplay=1|t=37/245")
    }

    @Test(arguments: [
        ("http://[::1]:4443/abc/song.mp3", "local"),
        ("http://127.0.0.1:4443/abc/song.mp3", "local"),
        ("http://localhost:4443/abc/song.mp3", "local"),
        ("http://192.168.1.20:4443/abc/song.mp3", "remote")
    ])
    func itemFailed_shouldReportOnlyWhetherTheFailingHostIsTheDevice(url: String, host: String) throws {
        let error = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorCannotConnectToHost,
            userInfo: [NSURLErrorFailingURLErrorKey: try #require(URL(string: url))]
        )

        #expect(itemFailed(error).eventReason == "itemFailed:NSURLErrorDomain:-1004|host=\(host)|airplay=0|t=0/-")
    }

    @Test
    func itemFailed_shouldFindTheFailingHostOnTheUnderlyingError() {
        let underlying = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorCannotConnectToHost,
            userInfo: [NSURLErrorFailingURLStringErrorKey: "http://127.0.0.1:4443/abc/song.mp3"]
        )
        let error = NSError(domain: "AVFoundationErrorDomain", code: -11800, userInfo: [NSUnderlyingErrorKey: underlying])

        #expect(
            itemFailed(error).eventReason ==
            "itemFailed:AVFoundationErrorDomain:-11800|u=NSURLErrorDomain:-1004|host=local|airplay=0|t=0/-"
        )
    }

    @Test
    func reasonsWithoutDetail_shouldReportTheirOwnName() {
        #expect(AudioPlaybackFailureReason.urlUnresolved.eventReason == "urlUnresolved")
        #expect(AudioPlaybackFailureReason.takenDown.eventReason == "takenDown")
        #expect(AudioPlaybackFailureReason.queueEmpty.eventReason == "queueEmpty")
    }

    @Test
    func context_shouldFollowTheReason() {
        let context = AudioPlaybackFailureContext(needsStreamingServer: true, isStreamingServerRunning: false, wasInterrupted: true)

        #expect(AudioPlaybackFailureReason.urlUnresolved.eventReason(in: context) == "urlUnresolved|stream=1|srv=0|intr=1")
    }

    @Test
    func context_withoutATrack_shouldLeaveTheStreamingNeedOut() {
        let context = AudioPlaybackFailureContext(needsStreamingServer: nil, isStreamingServerRunning: true, wasInterrupted: false)

        #expect(AudioPlaybackFailureReason.queueEmpty.eventReason(in: context) == "queueEmpty|srv=1|intr=0")
    }

    @Test
    func eventReasonInContext_shouldBeCapped() {
        let reason = itemFailed(NSError(domain: String(repeating: "a", count: 2000), code: 1))
        let context = AudioPlaybackFailureContext(needsStreamingServer: true, isStreamingServerRunning: true, wasInterrupted: false)

        let eventReason = reason.eventReason(in: context)

        #expect(eventReason.count == 500)
        #expect(eventReason.hasPrefix("itemFailed:aaa"))
    }

    private func itemFailed(
        _ error: NSError?,
        isAirPlayActive: Bool = false,
        position: TimeInterval = 0,
        duration: TimeInterval? = nil
    ) -> AudioPlaybackFailureReason {
        .itemFailed(PlaybackItemFailure(error: error, isAirPlayActive: isAirPlayActive, position: position, duration: duration))
    }
}
