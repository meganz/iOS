import MEGAVideoPlayer

public final class MockVideoPlaybackLoopUseCase: VideoPlaybackLoopUseCaseProtocol, @unchecked Sendable {
    public private(set) var isLoopEnabled: Bool
    public private(set) var setLoopEnabledCallCount = 0

    public init(isLoopEnabled: Bool = false) {
        self.isLoopEnabled = isLoopEnabled
    }

    public func setLoopEnabled(_ enabled: Bool) {
        setLoopEnabledCallCount += 1
        isLoopEnabled = enabled
    }
}
