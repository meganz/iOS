import Foundation
import MEGAVideoPlayer

public final class MockStreamingUseCase: StreamingUseCaseProtocol {
    public var startStreamingCallCount = 0
    public var stopStreamingCallCount = 0
    public var streamingLink: URL? = URL(string: "test_URL")

    public init() {}

    public var isStreaming: Bool = false

    public func startStreaming() {
        startStreamingCallCount += 1
    }

    public func stopStreaming() {
        stopStreamingCallCount += 1
    }

    public func streamingLink(for node: any PlayableNode) -> URL? {
        streamingLink
    }
}
