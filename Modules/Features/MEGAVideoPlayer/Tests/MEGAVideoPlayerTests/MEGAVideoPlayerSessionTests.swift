@testable import MEGAVideoPlayer
import Testing

@MainActor
struct MEGAVideoPlayerSessionTests {
    @Test
    func stop_endsTheRunningPictureInPictureSession() {
        let host = MockPictureInPictureHost()
        VideoPlayerPictureInPictureSession.begin(hostedBy: host)

        MEGAVideoPlayerSession.stop()

        #expect(host.endPictureInPictureSessionCallCount == 1)
        #expect(!VideoPlayerPictureInPictureSession.isHosted(by: host))
    }

    @Test
    func stop_withNoSessionRunning_doesNothing() {
        let host = MockPictureInPictureHost()
        VideoPlayerPictureInPictureSession.begin(hostedBy: host)
        VideoPlayerPictureInPictureSession.relinquish(by: host)

        MEGAVideoPlayerSession.stop()

        #expect(host.endPictureInPictureSessionCallCount == 0)
    }
}

@MainActor
private final class MockPictureInPictureHost: PictureInPictureHost {
    private(set) var endPictureInPictureSessionCallCount = 0

    func endPictureInPictureSession() {
        endPictureInPictureSessionCallCount += 1
    }
}
