import MEGADomain
import MEGADomainMock
import Testing

@Suite("StreamingUseCaseTests")
struct StreamingUseCaseTests {
    private static let highBitrate: Float = 20_000_000
    private static let lowBitrate: Float = 5_000_000

    private static func makeSUT(
        repository: MockStreamingRepository = MockStreamingRepository()
    ) -> (sut: StreamingUseCase, repository: MockStreamingRepository) {
        (StreamingUseCase(repository: repository), repository)
    }

    @Test("installs a throttle of bitrate x rate x 3 for high bitrate media")
    func highBitrate_shouldInstallScaledThrottle() {
        let (sut, repository) = Self.makeSUT()

        let didInstall = sut.updateThrottleBitrate(totalBitrate: Self.highBitrate, playbackRate: 2)

        #expect(didInstall)
        #expect(repository.throttleBitrates == [UInt64(Self.highBitrate * 2 * 3)])
    }

    @Test("clamps playback rates below 1x, so slow motion keeps full speed headroom")
    func slowPlaybackRate_shouldBeClampedToOne() {
        let (sut, repository) = Self.makeSUT()

        sut.updateThrottleBitrate(totalBitrate: Self.highBitrate, playbackRate: 0.5)

        #expect(repository.throttleBitrates == [UInt64(Self.highBitrate * 3)])
    }

    @Test("removes the throttle for media below the high bitrate threshold")
    func lowBitrate_shouldRemoveThrottle() {
        let (sut, repository) = Self.makeSUT()

        let didInstall = sut.updateThrottleBitrate(totalBitrate: Self.lowBitrate, playbackRate: 1)

        #expect(didInstall == false)
        #expect(repository.throttleBitrates == [0])
    }

    @Test("leaves media sitting exactly on the threshold uncapped")
    func bitrateExactlyAtThreshold_shouldRemoveThrottle() {
        let (sut, repository) = Self.makeSUT()

        let didInstall = sut.updateThrottleBitrate(totalBitrate: 15_000_000, playbackRate: 1)

        #expect(didInstall == false)
        #expect(repository.throttleBitrates == [0])
    }

    @Test("removes the throttle when the bitrate could not be measured")
    func nonFiniteBitrate_shouldRemoveThrottle() {
        let (sut, repository) = Self.makeSUT()

        let didInstall = sut.updateThrottleBitrate(totalBitrate: .nan, playbackRate: 1)

        #expect(didInstall == false)
        #expect(repository.throttleBitrates == [0])
    }

    @Test("falls back to 1x when the playback rate is not a usable number")
    func nonFinitePlaybackRate_shouldFallBackToOne() {
        let (sut, repository) = Self.makeSUT()

        sut.updateThrottleBitrate(totalBitrate: Self.highBitrate, playbackRate: .nan)

        #expect(repository.throttleBitrates == [UInt64(Self.highBitrate * 3)])
    }

    @Test("resets the throttle to uncapped")
    func reset_shouldSetThrottleToZero() {
        let (sut, repository) = Self.makeSUT()

        sut.resetThrottleBitrate()

        #expect(repository.throttleBitrates == [0])
    }
}
