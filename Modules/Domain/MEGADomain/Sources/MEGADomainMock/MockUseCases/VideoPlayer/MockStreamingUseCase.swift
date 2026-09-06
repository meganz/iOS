import Foundation
import MEGADomain

public final class MockStreamingUseCase: StreamingUseCaseProtocol, @unchecked Sendable {
    public var startStreamingCallCount = 0
    public var stopStreamingCallCount = 0
    public var streamingLink: URL? = URL(string: "test_URL")
    public var streamingLinkCallCount = 0
    public var updateThrottleBitrateCalls: [(totalBitrate: Float, playbackRate: Float)] = []
    public var resetThrottleBitrateCallCount = 0

    /// Value returned by `updateThrottleBitrate(totalBitrate:playbackRate:)`, standing in for the
    /// real threshold decision.
    public var didInstallThrottle: Bool

    public init(didInstallThrottle: Bool = false) {
        self.didInstallThrottle = didInstallThrottle
    }

    public var isStreaming: Bool = false

    public func startStreaming() {
        startStreamingCallCount += 1
    }

    public func stopStreaming() {
        stopStreamingCallCount += 1
    }

    public func streamingLink(for node: any PlayableNode) -> URL? {
        streamingLinkCallCount += 1
        return streamingLink
    }

    @discardableResult
    public func updateThrottleBitrate(totalBitrate: Float, playbackRate: Float) -> Bool {
        updateThrottleBitrateCalls.append((totalBitrate: totalBitrate, playbackRate: playbackRate))
        return didInstallThrottle
    }

    public func resetThrottleBitrate() {
        resetThrottleBitrateCallCount += 1
    }
}
